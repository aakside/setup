/* SPDX-License-Identifier: MIT
 * Enable upstream libinput three-finger drag on Magic Trackpad 2 only.
 * Loaded solely by the user's GNOME Shell systemd service.
 * No events are synthesized, consumed, logged, or modified here.
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <libinput.h>

static pthread_once_t once = PTHREAD_ONCE_INIT;
static __typeof__(libinput_get_event) *next_event;
static __typeof__(libinput_event_get_type) *event_type;
static __typeof__(libinput_event_get_device) *event_device;
static __typeof__(libinput_device_get_id_vendor) *vendor;
static __typeof__(libinput_device_get_id_product) *product;
static __typeof__(libinput_device_config_3fg_drag_get_finger_count) *finger_count;
static __typeof__(libinput_device_config_3fg_drag_set_enabled) *set_drag;
static __typeof__(libinput_device_config_3fg_drag_get_enabled) *get_drag;

static void resolve(void)
{
#define RESOLVE(target, name) target = dlsym(RTLD_NEXT, #name)
    RESOLVE(next_event, libinput_get_event);
    RESOLVE(event_type, libinput_event_get_type);
    RESOLVE(event_device, libinput_event_get_device);
    RESOLVE(vendor, libinput_device_get_id_vendor);
    RESOLVE(product, libinput_device_get_id_product);
    RESOLVE(finger_count, libinput_device_config_3fg_drag_get_finger_count);
    RESOLVE(set_drag, libinput_device_config_3fg_drag_set_enabled);
    RESOLVE(get_drag, libinput_device_config_3fg_drag_get_enabled);
#undef RESOLVE
    if (!event_type || !event_device || !vendor || !product ||
        !finger_count || !set_drag || !get_drag)
        fprintf(stderr, "[apple-three-finger-drag] API unavailable; leaving input unchanged\n");
}

struct libinput_event *libinput_get_event(struct libinput *li)
{
    pthread_once(&once, resolve);
    if (!next_event)
        return NULL;
    struct libinput_event *event = next_event(li);
    if (!event || !event_type || !event_device || !vendor || !product ||
        !finger_count || !set_drag || !get_drag ||
        event_type(event) != LIBINPUT_EVENT_DEVICE_ADDED)
        return event;
    struct libinput_device *device = event_device(event);
    if (!device)
        return event;
    unsigned int v = vendor(device);
    if ((v != 0x05ac && v != 0x004c) || product(device) != 0x0265 ||
        finger_count(device) < 3)
        return event;
    enum libinput_config_status status =
        set_drag(device, LIBINPUT_CONFIG_3FG_DRAG_ENABLED_3FG);
    fprintf(stderr, "[apple-three-finger-drag] %04x:0265 status=%d enabled=%d\n",
            v, status, get_drag(device));
    return event;
}
