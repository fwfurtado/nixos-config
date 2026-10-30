#include "obsbot-controls.h"

#include <dev/devs.hpp>

#include <cstdio>
#include <memory>

namespace {
std::shared_ptr<Device> tiny3_lite()
{
    for (const auto &device : Devices::get().getDevList()) {
        if (device->productType() == ObsbotProdTiny3Lite && device->isInited())
            return device;
    }
    return {};
}

int failed(const char *operation, int result)
{
    std::fprintf(stderr, "OBSBOT %s failed (SDK result %d)\n", operation, result);
    return -1;
}
} // namespace

extern "C" void obsbot_start(void)
{
    // The SDK otherwise logs the camera serial and device identifiers to stderr.
    static bool started = false;
    if (started)
        return;
    dev_set_log_handler([](int32_t, const char *, va_list, void *) {}, nullptr);
    Devices::get().setEnableMdnsScan(false);
    started = true;
}

extern "C" int obsbot_activate(void)
{
    auto device = tiny3_lite();
    if (!device)
        return 0;
    if (device->cameraStatus().tiny.dev_status != Device::DevStatusRun) {
        int result = device->cameraSetDevRunStatusR(Device::DevStatusRun);
        if (result != RM_RET_OK)
            return failed("waking camera", result);
    }

    Device::DevTargetSelection target{};
    target.selection_type = Device::DevTargetSelectionTypeCenter;
    target.class_type = Device::DevTargetClassTypeHuman;
    target.zoom_type = Device::DevTargetZoomTypeNormal;
    target.view_type = Device::DevTargetViewTypeIgnored;
    int result = device->aiSetSelectedTargetR(target);
    if (result != RM_RET_OK)
        return failed("selecting human target", result);
    result = device->aiSetTargetZoomTypeR(Device::DevTargetZoomTypeFullBody);
    if (result != RM_RET_OK)
        return failed("enabling full-body auto zoom", result);
    return 1;
}

extern "C" int obsbot_sleep(void)
{
    auto device = tiny3_lite();
    if (!device)
        return 0;
    int result = device->cameraSetDevRunStatusR(Device::DevStatusSleep);
    return result == RM_RET_OK ? 1 : failed("sleeping camera", result);
}
