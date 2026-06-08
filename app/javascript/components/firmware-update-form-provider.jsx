import { useState, useEffect, useCallback } from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import { Form, Loading } from "@carbon/react";
import FirmwareField from "./form/fields/firmware_field.jsx";

const API = window.API;

const applyFirmwareUpdate = (values) => {
  const firmwareField = values['firmwareField'];

  const resources = Object.keys(firmwareField).map(id => ({
    href: `${window.location.origin}/api/physical_servers/${id}`,
    firmware_names: firmwareField[id]
  }));

  API.post("/api/physical_servers/", {
    action: "apply_firmware_update_ansible",
    resources: resources,
  });
};

const getPhysicalServerData = (providerID) => {
  const uri = `/api/physical_servers?attributes=id,name,hardware.firmwares&expand=resources&filter[]=ems_id=${providerID}`;
  return API.get(uri).then((data) => data.resources.map(resource => ({
    id: resource.id,
    name: resource.name,
    firmwares: resource?.hardware?.firmwares || [],
  })));
};

const FirmwareUpdateFormProvider = ({ dispatch }) => {
  const [physicalServerList, setPhysicalServerList] = useState([]);
  const [values, setValues] = useState({});
  const [isLoading, setIsLoading] = useState(true);
  const [isValid, setIsValid] = useState(false);

  const handleFieldChange = useCallback((fieldName, fieldValue, isFieldValid) => {
    setValues(prev => ({
      ...prev,
      [fieldName]: fieldValue
    }));
    setIsValid(isFieldValid);
  }, []);

  useEffect(() => {
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
    getPhysicalServerData(ManageIQ.record.recordId)
      .then((serverList) => {
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
        validate={true}
        physicalServerData={physicalServerList}
        onChange={(value, isValid) => handleFieldChange('firmwareField', value, isValid)}
      />
    </Form>
  );
};

FirmwareUpdateFormProvider.propTypes = {
  dispatch: PropTypes.func.isRequired,
};

export default connect()(FirmwareUpdateFormProvider);
