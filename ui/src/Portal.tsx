import * as ReactDOM from "react-dom";

export default function Portal(props: { targetID: string, children: React.ReactNode }) {
    const target = document.getElementById(props.targetID);
    if (target == null)
        return null;
    return ReactDOM.createPortal(props.children, target);
}