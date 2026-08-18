import React, { useState, useEffect, useCallback } from "react";
import { useMiqDispatch } from "@@miq-redux/miq-hooks";
import { Form, Loading } from "@carbon/react";
import FirmwareField from "./form/fields/firmware_field";
import type {
  FirmwareType,
  PhysicalServerDataType,
  FirmwareFieldType,
} from "./form/common_types";

type PhysicalServerResourceType = {
  id: string;
  name: string;
  hardware?: {
    firmwares?: FirmwareType[];
  };
};

type ApiResponseType = {
  resources: PhysicalServerResourceType[];
};

type ApplyFirmwareResourceType = {
  href: string;
  firmware_names: string[];
};

type FormValuesType = {
  firmwareField?: FirmwareFieldType;
};

const applyFirmwareUpdate = (values: FormValuesType): void => {
  const firmwareField = values?.firmwareField || {};

  const resources: ApplyFirmwareResourceType[] = Object.keys(firmwareField).map(
    (id) => ({
      href: `${window.location.origin}/api/physical_servers/${id}`,
      firmware_names: firmwareField?.[id],
    }),
  );

  API.post("/api/physical_servers/", {
    action: "apply_firmware_update_ansible",
    resources: resources,
  });
};

const getPhysicalServerData = async (
  providerID: string | number,
): Promise<PhysicalServerDataType[]> => {
  const uri = `/api/physical_servers?attributes=id,name,hardware.firmwares&expand=resources&filter[]=ems_id=${providerID}`;
  const data = await API.get<ApiResponseType>(uri);
  return data.resources.map((resource) => ({
    id: resource.id,
    name: resource.name,
    firmwares: resource?.hardware?.firmwares || [],
  }));
};

const FirmwareUpdateFormProvider: React.FC = () => {
  const dispatch = useMiqDispatch();
  const [physicalServerList, setPhysicalServerList] = useState<
    PhysicalServerDataType[]
  >([]);
  const [values, setValues] = useState<FormValuesType>({});
  const [isLoading, setIsLoading] = useState(true);
  const [isValid, setIsValid] = useState(false);

  const handleFieldChange = useCallback(
    (
      fieldName: string,
      fieldValue: FirmwareFieldType,
      isFieldValid: boolean,
    ) => {
      setValues((prev) => ({
        ...prev,
        [fieldName]: fieldValue,
      }));
      setIsValid(isFieldValid);
    },
    [],
  );

  useEffect(() => {
    // TODO: Modernize Redux - Convert form-buttons-reducer.js to Redux Toolkit slice
    // This would replace manual action types with auto-generated action creators:
    // dispatch(init({ newRecord: true, pristine: true }));
    // dispatch(customLabel("Apply"));
    // dispatch(callbacks({ addClicked: () => applyFirmwareUpdate(values) }));

    // Initialize form buttons
    dispatch({
      type: "FormButtons.init",
      payload: {
        newRecord: true,
        pristine: true,
        addClicked: () => {
          applyFirmwareUpdate(values);
        },
      },
    });
    dispatch({
      type: "FormButtons.customLabel",
      payload: "Apply",
    });

    // Load physical server data
    getPhysicalServerData(ManageIQ.record.recordId).then((serverList) => {
      setPhysicalServerList(serverList);
      setIsLoading(false);
    });
  }, [dispatch, values]);

  useEffect(() => {
    // Update form button state
    dispatch({
      type: "FormButtons.saveable",
      payload: isValid,
    });
    dispatch({
      type: "FormButtons.pristine",
      payload: Object.keys(values).length === 0,
    });
  }, [dispatch, isValid, values]);

  if (isLoading) {
    return <Loading className="export-spinner" withOverlay={false} small />;
  }

  return (
    <Form>
      <FirmwareField
        name="firmwareField"
        physicalServerData={physicalServerList}
        onChange={(value, isValid) =>
          handleFieldChange("firmwareField", value, isValid)
        }
      />
    </Form>
  );
};

export default FirmwareUpdateFormProvider;
