import React, { useState, useEffect, useCallback } from "react";
import { useMiqDispatch } from "@@miq-redux/miq-hooks";
import { Form, Stack, Loading } from "@carbon/react";
import PhysicalServerField from "./form/fields/physical_server_field";
import ConfigPatternField from "./form/fields/config_pattern_field";
import type { OptionType } from "./form/common_types";
import "./style/apply-config-pattern-form.scss";

type ResourceType = {
  href: string;
  name: string;
  manager_ref: string;
};

type ApiResponseType = {
  resources: ResourceType[];
};

type FormValuesType = {
  configPatternField?: string;
  physicalServerField?: string[];
};

type ApplyPatternResourceType = {
  href: string;
  pattern_id: string;
};

const applyPattern = (values: FormValuesType): void => {
  const resources: ApplyPatternResourceType[] = (
    values.physicalServerField || []
  ).map((href) => ({
    href: href,
    pattern_id: values?.configPatternField || "",
  }));

  API.post("/api/physical_servers/", {
    action: "apply_config_pattern_ansible",
    resources: resources,
  });
};

const getPhysicalServerData = async (
  providerID: string | number,
): Promise<OptionType[]> => {
  const uri = `/api/physical_servers?attributes=name,href&expand=resources&filter[]=ems_id=${providerID}`;
  const data = await API.get<ApiResponseType>(uri);
  return data.resources.map((resource) => ({
    value: resource.href,
    label: resource.name,
  }));
};

const getConfigPatternData = async (
  providerID: string | number,
): Promise<OptionType[]> => {
  const uri = `/api/customization_scripts?attributes=manager_ref,name&expand=resources&filter[]=type='ManageIQ::Providers::Lenovo::PhysicalInfraManager::ConfigPattern'&filter[]=manager_id=${providerID}`;
  const data = await API.get<ApiResponseType>(uri);
  return data.resources.map((resource) => ({
    value: resource.manager_ref,
    label: resource.name,
  }));
};

const ApplyConfigPatternFormProvider: React.FC = () => {
  const dispatch = useMiqDispatch();
  const [configPatternList, setConfigPatternList] = useState<OptionType[]>([]);
  const [physicalServerList, setPhysicalServerList] = useState<OptionType[]>(
    [],
  );
  const [physicalServerFieldDisabled, setPhysicalServerFieldDisabled] =
    useState(true);
  const [values, setValues] = useState<FormValuesType>({});
  const [isLoading, setIsLoading] = useState(true);
  const [isValid, setIsValid] = useState(false);

  const updateServers = useCallback((patternValue: string) => {
    // If pattern value is empty or placeholder, clear the server list and disable the field
    if (!patternValue || patternValue === "placeholder-item") {
      setPhysicalServerList([]);
      setPhysicalServerFieldDisabled(true);
      // Clear the physical server field value
      setValues((prev) => ({
        ...prev,
        physicalServerField: [],
      }));
      return;
    }

    // Otherwise, load the server list
    getPhysicalServerData(ManageIQ.record.recordId).then((serverList) => {
      setPhysicalServerList(serverList);
      setPhysicalServerFieldDisabled(false);
    });
  }, []);

  const handleFieldChange = useCallback(
    (
      fieldName: string,
      fieldValue: string | string[],
      isFieldValid: boolean,
    ) => {
      setValues((prev) => ({
        ...prev,
        [fieldName]: fieldValue,
      }));

      // Check if all required fields are valid
      const newIsValid =
        isFieldValid &&
        (fieldName === "configPatternField"
          ? values?.physicalServerField?.length
          : values?.configPatternField);

      setIsValid(!!newIsValid);
    },
    [values],
  );

  useEffect(() => {
    // TODO: Modernize Redux - Convert form-buttons-reducer.js to Redux Toolkit slice
    // This would replace manual action types with auto-generated action creators:
    // dispatch(init({ newRecord: true, pristine: true }));
    // dispatch(customLabel("Apply"));
    // dispatch(callbacks({ addClicked: () => applyPattern(values) }));

    // Initialize form buttons
    dispatch({
      type: "FormButtons.init",
      payload: {
        newRecord: true,
        pristine: true,
        addClicked: () => {
          applyPattern(values);
        },
      },
    });
    dispatch({
      type: "FormButtons.customLabel",
      payload: "Apply",
    });

    // Load config patterns
    getConfigPatternData(ManageIQ.record.recordId).then((patternList) => {
      setConfigPatternList(patternList);
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
    <Form className="apply-config-pattern-form">
      <Stack gap={6}>
        <ConfigPatternField
          name="configPatternField"
          updateChildren={updateServers}
          configPatternData={configPatternList}
          onChange={(value, isValid) =>
            handleFieldChange("configPatternField", value, isValid)
          }
        />
        <PhysicalServerField
          physicalServerData={physicalServerList}
          disabled={physicalServerFieldDisabled}
          onChange={(value, isValid) =>
            handleFieldChange("physicalServerField", value, isValid)
          }
        />
      </Stack>
    </Form>
  );
};

export default ApplyConfigPatternFormProvider;
