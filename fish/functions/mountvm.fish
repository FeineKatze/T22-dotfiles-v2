function mountvm
    switch $argv[1]
        case win10
            sudo qemu-nbd --connect=/dev/nbd0 /var/lib/libvirt/images/win10.qcow2
            sleep 1
            sudo mount /dev/nbd0p3 /run/media/christopher/Win10

        case win11
            sudo qemu-nbd --connect=/dev/nbd1 /var/lib/libvirt/images/win11.qcow2
            sleep 1
            sudo mount /dev/nbd1p3 /run/media/christopher/Win11

        case '*'
            echo "Usage: mountvm [win10|win11]"
    end
end
