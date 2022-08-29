#!/usr/bin/python3
import objc
from AppKit import NSWorkspace
from Foundation import NSURL


workspace = NSWorkspace.sharedWorkspace()


def get_app_path(app_name: str) -> NSURL:
    """
    Returns a URL (filesystem path prefixed with 'file://' scheme) to an
    application specified by name, absolute path or bundle ID.
    :param str app: name, absolute filesystem path or bundle ID to look up the URL for
    :raises:
        ApplicationNotFound: when no matching application was found
    """
    path = workspace.fullPathForApplication_(app_name)

    if path is None:
        raise ValueError(
            "Could not find an application named '{}'.".format(app_name)
        )

    return NSURL.fileURLWithPath_(path)


def set_default_scheme(scheme: str, app: str) -> None:
    """
    Sets a default handler for a specific URL scheme.
    :param str scheme: URL scheme to set the default handler for
    :param str app: absolute filesystem path, name or bundle ID of the handler
    """

    path = get_app_path(app)

    workspace.setDefaultApplicationAtURL_toOpenURLsWithScheme_completionHandler_(  # noqa: E501
        path, scheme, objc.nil
    )


if __name__ == '__main__':
    import sys
    scheme = sys.argv[4]
    app = sys.argv[5]
    print("Setting default handler for scheme {} to app {}".format(scheme, app))
    set_default_scheme(scheme, app)
