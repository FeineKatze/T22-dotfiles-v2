function monset
    switch $argv[1]
        case home
            cp ~/.config/hypr/modules/sets/home/monitors.conf ~/.config/hypr/modules/monitors.conf
            cp ~/.config/hypr/modules/sets/home/windows_workspaces.conf ~/.config/hypr/modules/windows_workspaces.conf
        case jani
            cp ~/.config/hypr/modules/sets/jani/monitors.conf ~/.config/hypr/modules/monitors.conf
            cp ~/.config/hypr/modules/sets/jani/windows_workspaces.conf ~/.config/hypr/modules/windows_workspaces.conf
        case '*'
            echo "Only [home|jani]"
    end
end
