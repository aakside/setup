/* SPDX-License-Identifier: MIT
 * Enumerate only the explicitly supplied input nodes, report configuration,
 * and exit. Does not grab devices or wait for/print user input events.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <libinput.h>
static int open_device(const char *path, int flags, void *data)
{ (void)data; int fd = open(path, flags); return fd < 0 ? -errno : fd; }
static void close_device(int fd, void *data)
{ (void)data; close(fd); }
int main(int argc, char **argv)
{
    const struct libinput_interface interface = {open_device, close_device};
    struct libinput *li = libinput_path_create_context(&interface, NULL);
    if (!li || argc < 2) return 2;
    int failed = 0, found = 0;
    for (int i = 1; i < argc; i++)
        if (!libinput_path_add_device(li, argv[i])) failed = 1;
    struct libinput_event *event;
    while ((event = libinput_get_event(li))) {
        if (libinput_event_get_type(event) == LIBINPUT_EVENT_DEVICE_ADDED) {
            struct libinput_device *d = libinput_event_get_device(event);
            printf("%s vendor=%04x product=%04x supported-fingers=%d enabled=%d\n",
                libinput_device_get_name(d), libinput_device_get_id_vendor(d),
                libinput_device_get_id_product(d),
                libinput_device_config_3fg_drag_get_finger_count(d),
                libinput_device_config_3fg_drag_get_enabled(d));
            found++;
        }
        libinput_event_destroy(event);
    }
    libinput_unref(li);
    return failed || !found;
}
