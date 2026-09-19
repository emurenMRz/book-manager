import * as React from "react";

export const UserType = {
	None: -1,
	Regular: 0,
	Temp: 1,
} as const;
export type UserType = typeof UserType[keyof typeof UserType];

export const UserTypeContext = React.createContext({ type: UserType.None as UserType, changeType: (newType: UserType) => { } })