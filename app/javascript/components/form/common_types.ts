export type { OptionType } from "@@miq-types/forms";

export type FirmwareType = {
  name: string;
};

export type FirmwareFieldType = Record<string, string[]>;

export type PhysicalServerDataType = {
  id: string;
  name: string;
  firmwares: FirmwareType[];
};
