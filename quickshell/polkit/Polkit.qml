pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Polkit

QtObject {
    id: root

    property PolkitAgent agent: PolkitAgent {
        path: "/org/quickshell/Polkit"

        onFlowChanged: {
            if (flow && flow.identities.length > 0 && !flow.selectedIdentity)
                flow.selectedIdentity = flow.identities[0];
        }
    }

    readonly property bool isActive: root.agent.isActive
    readonly property var flow: root.agent.flow

    function submit(password) {
        if (root.flow)
            root.flow.submit(password);
    }

    function cancel() {
        if (root.flow)
            root.flow.cancelAuthenticationRequest();
    }
}
