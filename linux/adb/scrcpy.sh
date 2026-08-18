    # Scrcpy
    function SCRCPY

        alias Android-Tools='adb version'
        alias ADBconnect="~/File/Script/adb/adbconnect.sh"
        alias TCPconnect="~/File/Script/adb/tcp.sh"
        alias scrmore="bash ~/File/Script/adb/scrcpymore.sh"

        set_color -o cyan; echo "Available Apps"; set_color normal
        echo -n " • "; set_color yellow; echo "Scrcpy"; set_color normal
        echo -n "   ├── "; set_color cyan; echo "Android-Tools"; set_color normal
        echo -n "   ├── "; set_color cyan; echo "ADBconnect"; set_color normal
        echo -n "   ├── "; set_color cyan; echo "TCPconnect"; set_color normal
        echo -n "   ├── "; set_color cyan; echo "ForwardTab8030"; set_color normal
        echo -n "   ├── "; set_color cyan; echo "scrcpy"; set_color normal
        echo -n "   └── "; set_color cyan; echo "scrmore"; set_color normal
        echo -n "        ├── "; set_color red; echo "novideo"; set_color normal
        echo -n "        ├── "; set_color red; echo "novirtual"; set_color normal
        echo -n "        ├── "; set_color red; echo "justinput"; set_color normal
        echo -n "        ├── "; set_color red; echo "inputandaudio"; set_color normal
        echo -n "        ├── "; set_color red; echo "vlc"; set_color normal
        echo -n "        └── "; set_color red; echo "other code"; set_color normal
        echo ""


        function scrcpy-list
                set_color -o cyan; echo "Available Apps"; set_color normal
                echo -n " • "; set_color yellow; echo "Scrcpy"; set_color normal                 
                echo -n "   ├── "; set_color cyan; echo "ADBconnect"; set_color normal
                echo -n "   ├── "; set_color cyan; echo "TCPconnect"; set_color normal
                echo -n "   ├── "; set_color cyan; echo "scrcpy"; set_color normal
                echo -n "   └── "; set_color cyan; echo "scrmore"; set_color normal
                echo -n "        ├── "; set_color red; echo "novideo"; set_color normal
                echo -n "        ├── "; set_color red; echo "novirtual"; set_color normal
                echo -n "        ├── "; set_color red; echo "justinput"; set_color normal
                echo -n "        ├── "; set_color red; echo "inputandaudio"; set_color normal
                echo -n "        ├── "; set_color red; echo "vlc"; set_color normal
                echo -n "        └── "; set_color red; echo "other code"; set_color normal
                echo ""
        end


        end