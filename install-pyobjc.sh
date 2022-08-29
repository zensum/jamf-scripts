#!/bin/bash

/usr/bin/python3 --version

if [ $? -ne 0 ]; then
    echo "Error: Python is not installed."
    echo "Install XCode CLI"
    exit 1
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

