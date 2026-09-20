function umountvm
    switch $argv[1]
        case win10
            sudo umount /dev/nbd0p3
            sudo qemu-nbd --disconnect /dev/nbd0

        case win11
            sudo umount /dev/nbd1p3
            sudo qemu-nbd --disconnect /dev/nbd1

        case '*'
            echo "Usage: umountvm [win10|win11]"
    end
end
