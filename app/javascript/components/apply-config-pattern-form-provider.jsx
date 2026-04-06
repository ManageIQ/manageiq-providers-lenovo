import React, { useState, useEffect, useCallback } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import { Form, Stack, Loading } from "@carbon/react";
import PhysicalServerField from "./form/fields/physical_server_field.js";
import ConfigPatternField from "./form/fields/config_pattern_field.js";
import './style/apply-config-pattern-form.css';

const API = window.API;

const applyPattern = (values) => {
  const resources = values.physicalServerField.map(href => ({
    href: href,
    pattern_id: values.configPatternField
  }));
  API.post("/api/physical_servers/", {
    action: "apply_config_pattern_ansible",
    resources: resources,
  });
};

const getPhysicalServerData = (providerID) => {
  const uri = `/api/physical_servers?attributes=name,href&expand=resources&filter[]=ems_id=${providerID}`;
  return API.get(uri).then((data) => data.resources.map(resource => ({
    value: resource.href,
    label: resource.name,
  })));
};

const getConfigPatternData = (providerID) => {
  const typeFilter = encodeURIComponent("type='ManageIQ::Providers::Lenovo::PhysicalInfraManager::ConfigPattern'");
  // const uri = `/api/customization_scripts?attributes=manager_ref,name&expand=resources&filter[]=${typeFilter}&filter[]=manager_id=${providerID}`;
  const uri = `/api/customization_scripts?attributes=manager_ref,name&expand=resources&filter[]=manager_id=${providerID}`;
  return API.get(uri).then((data) => data.resources.map(resource => ({
    value: resource.manager_ref,
    label: resource.name,
  })));
};

const ApplyConfigPatternFormProvider = ({ dispatch }) => {
  const [configPatternList, setConfigPatternList] = useState([]);
  const [physicalServerList, setPhysicalServerList] = useState([]);
  const [physicalServerFieldDisabled, setPhysicalServerFieldDisabled] = useState(true);
  const [values, setValues] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [isValid, setIsValid] = useState(false);

  const updateServers = useCallback((patternValue) => {
    // If pattern value is empty or placeholder, clear the server list and disable the field
    if (!patternValue || patternValue === 'placeholder-item') {
      setPhysicalServerList([]);
      setPhysicalServerFieldDisabled(true);
      // Clear the physical server field value
      setValues(prev => ({
        ...prev,
        physicalServerField: []
      }));
      return;
    }
    
    // Otherwise, load the server list
    getPhysicalServerData(ManageIQ.record.recordId)
      .then(serverList => {
        setPhysicalServerList(serverList);
        setPhysicalServerFieldDisabled(false);
      });
  }, []);

  const handleFieldChange = useCallback((fieldName, fieldValue, isFieldValid) => {
    setValues(prev => ({
      ...prev,
      [fieldName]: fieldValue
    }));

    // Check if all required fields are valid
    const newIsValid = fieldName === 'configPatternField' 
      ? isFieldValid && values.physicalServerField && values.physicalServerField.length > 0
      : values.configPatternField && isFieldValid;
    
    setIsValid(newIsValid);
  }, [values]);

  useEffect(() => {
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
    getConfigPatternData(ManageIQ.record.recordId)
      .then((patternList) => {
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
    <Form className='apply-config-pattern-form'>
      <Stack gap={6}>
          <ConfigPatternField
            name="configPatternField"
            validate={true}
            updateChildren={updateServers}
            configPatternData={configPatternList}
            onChange={(value, isValid) => handleFieldChange('configPatternField', value, isValid)}
          />
          <PhysicalServerField
            validate={true}
            name="physicalServerField"
            physicalServerData={physicalServerList}
            disabled={physicalServerFieldDisabled}
            onChange={(value, isValid) => handleFieldChange('physicalServerField', value, isValid)}
          />
      </Stack>
    </Form>
  );
};

ApplyConfigPatternFormProvider.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(ApplyConfigPatternFormProvider);
