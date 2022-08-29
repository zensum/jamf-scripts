#!/bin/bash

/usr/bin/python3 --version

if [ $? -ne 0 ]; then
    echo "Error: Python is not installed."
    echo "Install XCode dev tools"
else
    echo "Installing XCode dev tools"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/zensum/jamf-scripts/master/install-xcode-cli.sh)"
fi

/usr/bin/python3 <<EOF
try:
    import objc
except ImportError:
    exit(1)
EOF

if [ $? -ne 0 ]; then
    echo "Error: PyObjC is not installed."
    /usr/bin/python3 -m pip install PyObjC
fi

