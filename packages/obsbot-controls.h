#ifndef OBSBOT_CONTROLS_H
#define OBSBOT_CONTROLS_H

#ifdef __cplusplus
extern "C" {
#endif

/* Discovery is asynchronous. Call after opening the physical video stream. */
void obsbot_start(void);
/* 1: command applied; 0: camera not discovered yet; -1: command failed. */
int obsbot_activate(void);
int obsbot_sleep(void);

#ifdef __cplusplus
}
#endif

#endif
