#include "obsbot-controls.h"

#include <fcntl.h>
#include <unistd.h>

namespace {
void record(const char *event, size_t length)
{
    int fd = open("/run/tiny-camera-sdk-events", O_WRONLY | O_APPEND | O_CREAT | O_CLOEXEC, 0600);
    if (fd < 0 || write(fd, event, length) != static_cast<ssize_t>(length))
        _exit(1);
    close(fd);
}
}

extern "C" void obsbot_start(void) { }
extern "C" int obsbot_activate(void)
{
    record("active\n", 7);
    return 1;
}
extern "C" int obsbot_sleep(void)
{
    record("sleep\n", 6);
    return 1;
}
