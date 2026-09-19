import * as React from "react";
import { DataType } from "../contents/BookList";
import { TargetData } from "../contents/ChangeUserData";
import { SearchQuery } from "../header/Search";

export type BookListStatus = { mode: "BookList", dataType: DataType };
export type SearchStatus = { mode: "Search", searchQuery: SearchQuery };
export type ChangeUserDataStatus = { mode: "ChangeUserData", target: TargetData };
export type ContactStatus = { mode: "Contact" };
export type LogoutStatus = { mode: "Logout" };
export type ContentStatus = BookListStatus | SearchStatus | ChangeUserDataStatus | ContactStatus | LogoutStatus;

export const ContentStatusContext = React.createContext({ status: { mode: "BookList", dataType: DataType.ToBuyList } as ContentStatus, changeStatus: (newStatus: ContentStatus) => {} })