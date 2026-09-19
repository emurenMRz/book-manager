import * as React from "react";

export const DisplayType = {
	Thumb: "thumb",
	Simple: "simple",
	Detail: "detail",
} as const;
export type DisplayType = typeof DisplayType[keyof typeof DisplayType];

export const DisplayTypeContext = React.createContext({ type: DisplayType.Detail as DisplayType, changeType: (newType: DisplayType) => {} })