#define _GNU_SOURCE
#include <errno.h>
#include "obsbot-controls.h"
#include <fcntl.h>
#include <linux/videodev2.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define WIDTH 1280
#define HEIGHT 720
#define FRAME_SIZE (WIDTH * HEIGHT * 3 / 2)
#define V4L2_EVENT_PRI_CLIENT_USAGE (V4L2_EVENT_PRIVATE_START + 0x08e00000 + 1)
#define V4L2_CID_SUSTAIN_FRAMERATE (V4L2_CID_USER_BASE | 0xf001)

static volatile sig_atomic_t stopping;

static void on_signal(int signal_number)
{
    (void)signal_number;
    stopping = 1;
}

static void write_frame(int fd, const unsigned char *frame)
{
    ssize_t written = write(fd, frame, FRAME_SIZE);
    if (written != FRAME_SIZE) {
        if (written < 0)
            perror("writing virtual camera frame");
        else
            fprintf(stderr, "short virtual camera frame: %zd\n", written);
        exit(EXIT_FAILURE);
    }
}

static void set_control(int fd, uint32_t id, int value)
{
    struct v4l2_control control = { .id = id, .value = value };
    if (ioctl(fd, VIDIOC_S_CTRL, &control) < 0) {
        perror("setting camera control");
        exit(EXIT_FAILURE);
    }
}

static int apply_camera_controls(const char *camera)
{
    int fd = open(camera, O_RDWR | O_CLOEXEC);
    if (fd < 0) {
        perror("opening physical camera controls");
        return -1;
    }
    const struct v4l2_control controls[] = {
        { .id = V4L2_CID_AUTO_WHITE_BALANCE, .value = 0 },
        { .id = V4L2_CID_WHITE_BALANCE_TEMPERATURE, .value = 4000 },
        { .id = V4L2_CID_SATURATION, .value = 47 },
    };
    int result = 0;
    for (size_t i = 0; i < sizeof(controls) / sizeof(controls[0]); ++i) {
        if (ioctl(fd, VIDIOC_S_CTRL, &controls[i]) < 0) {
            perror("setting physical camera control");
            result = -1;
            break;
        }
    }
    close(fd);
    return result;
}

static pid_t start_camera(const char *ffmpeg, const char *camera, int *pipe_fd)
{
    int fds[2];
    if (pipe2(fds, O_CLOEXEC) < 0) {
        perror("creating camera pipe");
        return -1;
    }
    pid_t child = fork();
    if (child < 0) {
        perror("forking ffmpeg");
        close(fds[0]);
        close(fds[1]);
        return -1;
    }
    if (child == 0) {
        if (dup2(fds[1], STDOUT_FILENO) < 0)
            _exit(127);
        close(fds[0]);
        close(fds[1]);
        execl(ffmpeg, ffmpeg, "-hide_banner", "-loglevel", "error", "-nostdin",
              "-f", "v4l2", "-input_format", "mjpeg", "-video_size", "1280x720",
              "-framerate", "30", "-i", camera, "-an", "-pix_fmt", "yuv420p",
              "-f", "rawvideo", "pipe:1", (char *)NULL);
        _exit(127);
    }
    close(fds[1]);
    if (fcntl(fds[0], F_SETFL, O_NONBLOCK) < 0) {
        perror("setting camera pipe nonblocking");
        kill(child, SIGTERM);
        waitpid(child, NULL, 0);
        close(fds[0]);
        return -1;
    }
    *pipe_fd = fds[0];
    return child;
}

static void stop_camera(pid_t *child, int *pipe_fd)
{
    if (*pipe_fd >= 0) {
        close(*pipe_fd);
        *pipe_fd = -1;
    }
    if (*child > 0) {
        kill(*child, SIGTERM);
        for (int i = 0; i < 10; ++i) {
            pid_t result = waitpid(*child, NULL, WNOHANG);
            if (result == *child || (result < 0 && errno == ECHILD)) {
                *child = -1;
                return;
            }
            struct timespec delay = { .tv_nsec = 100000000 };
            nanosleep(&delay, NULL);
        }
        kill(*child, SIGKILL);
        waitpid(*child, NULL, 0);
        *child = -1;
    }
}

static long long now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000 + ts.tv_nsec / 1000000;
}

static int client_count(int fd, int previous)
{
    struct v4l2_event event;
    while (ioctl(fd, VIDIOC_DQEVENT, &event) == 0) {
        if (event.type == V4L2_EVENT_PRI_CLIENT_USAGE) {
            uint32_t count;
            memcpy(&count, event.u.data, sizeof(count));
            previous = count != 0;
        }
    }
    if (errno != EAGAIN && errno != ENOENT) {
        perror("reading virtual camera client event");
        exit(EXIT_FAILURE);
    }
    return previous;
}

static void write_black(int output, unsigned char *frame)
{
    memset(frame, 16, WIDTH * HEIGHT);
    memset(frame + WIDTH * HEIGHT, 128, FRAME_SIZE - WIDTH * HEIGHT);
    write_frame(output, frame);
}

int main(int argc, char **argv)
{
    if (argc != 4) {
        fprintf(stderr, "usage: %s VIRTUAL_DEVICE PHYSICAL_DEVICE FFMPEG\n", argv[0]);
        return EXIT_FAILURE;
    }
    struct sigaction action = { .sa_handler = on_signal };
    sigemptyset(&action.sa_mask);
    sigaction(SIGTERM, &action, NULL);
    sigaction(SIGINT, &action, NULL);
    signal(SIGPIPE, SIG_IGN);

    int output = open(argv[1], O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (output < 0) {
        perror("opening virtual camera");
        return EXIT_FAILURE;
    }
    struct v4l2_format format = { .type = V4L2_BUF_TYPE_VIDEO_OUTPUT };
    format.fmt.pix.width = WIDTH;
    format.fmt.pix.height = HEIGHT;
    format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV420;
    format.fmt.pix.field = V4L2_FIELD_NONE;
    if (ioctl(output, VIDIOC_S_FMT, &format) < 0 ||
        format.fmt.pix.width != WIDTH || format.fmt.pix.height != HEIGHT ||
        format.fmt.pix.pixelformat != V4L2_PIX_FMT_YUV420 ||
        format.fmt.pix.bytesperline != WIDTH || format.fmt.pix.sizeimage < FRAME_SIZE) {
        fprintf(stderr, "virtual camera does not support 1280x720 YUV420\n");
        close(output);
        return EXIT_FAILURE;
    }
    struct v4l2_event_subscription subscription = {
        .type = V4L2_EVENT_PRI_CLIENT_USAGE,
        .flags = V4L2_EVENT_SUB_FL_SEND_INITIAL,
    };
    if (ioctl(output, VIDIOC_SUBSCRIBE_EVENT, &subscription) < 0) {
        perror("subscribing to virtual camera client usage");
        close(output);
        return EXIT_FAILURE;
    }
    unsigned char *frame = malloc(FRAME_SIZE);
    if (!frame) {
        perror("allocating video frame");
        close(output);
        return EXIT_FAILURE;
    }
    write_black(output, frame);
    set_control(output, V4L2_CID_SUSTAIN_FRAMERATE, 1);

    pid_t child = -1;
    int pipe_fd = -1;
    int consumers = 0;
    int controls_applied = 0;
    int captured = 0;
    int sdk_started = 0;
    int sdk_active = 0;
    int sleep_pending = 0;
    long long sdk_retry_at = 0;
    long long sleep_deadline = 0;
    size_t received = 0;
    long long retry_at = 0;
    long long last_frame = now_ms();
    while (!stopping) {
        consumers = client_count(output, consumers);
        if (!consumers && child > 0) {
            stop_camera(&child, &pipe_fd);
            received = 0;
            controls_applied = 0;
            write_black(output, frame);
        }
        if (!consumers && captured) {
            captured = 0;
            sdk_active = 0;
            sleep_pending = 1;
            sdk_retry_at = 0;
            sleep_deadline = now_ms() + 10000;
        }
        if (!consumers && sleep_pending && now_ms() >= sdk_retry_at) {
            int result = obsbot_sleep();
            if (result == 1 || now_ms() >= sleep_deadline) {
                sleep_pending = 0;
            } else {
                sdk_retry_at = now_ms() + (result == 0 ? 250 : 3000);
            }
        }
        if (consumers && child < 0 && now_ms() >= retry_at) {
            sleep_pending = 0;
            sdk_retry_at = 0;
            sdk_active = 0;
            controls_applied = 0;
            child = start_camera(argv[3], argv[2], &pipe_fd);
            last_frame = now_ms();
            if (child < 0)
                retry_at = now_ms() + 3000;
        }
        struct pollfd fds[] = {
            { .fd = output, .events = POLLPRI },
            { .fd = pipe_fd, .events = POLLIN },
        };
        int ready = poll(fds, pipe_fd >= 0 ? 2 : 1, 250);
        if (ready < 0 && errno != EINTR) {
            perror("polling camera");
            break;
        }
        if (pipe_fd >= 0 && (fds[1].revents & (POLLIN | POLLHUP | POLLERR))) {
            ssize_t got = read(pipe_fd, frame + received, FRAME_SIZE - received);
            if (got > 0) {
                received += (size_t)got;
                last_frame = now_ms();
                if (received == FRAME_SIZE) {
                    captured = 1;
                    if (!sdk_started) {
                        obsbot_start();
                        sdk_started = 1;
                    }
                    if (!sdk_active && now_ms() >= sdk_retry_at) {
                        int result = obsbot_activate();
                        if (result == 1)
                            sdk_active = 1;
                        else
                            sdk_retry_at = now_ms() + (result == 0 ? 250 : 3000);
                    }
                    if (!controls_applied) {
                        if (apply_camera_controls(argv[2]) < 0) {
                            stop_camera(&child, &pipe_fd);
                            sdk_active = 0;
                            retry_at = now_ms() + 3000;
                            received = 0;
                            write_black(output, frame);
                            continue;
                        }
                        controls_applied = 1;
                    }
                    write_frame(output, frame);
                    received = 0;
                }
            } else if (got == 0 || errno != EAGAIN) {
                stop_camera(&child, &pipe_fd);
                sdk_active = 0;
                retry_at = now_ms() + 3000;
                received = 0;
                write_black(output, frame);
            }
        }
        if (child > 0 && now_ms() - last_frame > 5000) {
            fprintf(stderr, "physical camera stopped delivering frames\n");
            stop_camera(&child, &pipe_fd);
            retry_at = now_ms() + 3000;
            sdk_active = 0;
            received = 0;
            write_black(output, frame);
        }
    }
    stop_camera(&child, &pipe_fd);
    if (captured || sleep_pending)
        obsbot_sleep();
    free(frame);
    close(output);
    return stopping ? EXIT_SUCCESS : EXIT_FAILURE;
}
