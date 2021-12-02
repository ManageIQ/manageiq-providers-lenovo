import React from "react";
import PropTypes from "prop-types";
import { Loading } from 'carbon-components-react';
import connect from "react-redux/es/connect/connect";

class LenovoForm extends React.Component {
  constructor(props) {
    super(props);

    const fields = [].concat.apply([], [this.props.children]);
    const fieldsStatus = {};
    for (let i = 0; i < fields.length; i++) {
      let field = fields[i];
      fieldsStatus[field.props.name]=!field.props.validate || false ;
    }

    this.state = {
      fieldsStatus: fieldsStatus,
      fieldsValues: {},
    };

    this.updateModalState = this.updateModalState.bind(this);
    this.handleFormStateUpdate = this.handleFormStateUpdate.bind(this);
  }

  handleFormStateUpdate(formState) {
    this.props.dispatch({
      type: "FormButtons.saveable",
      payload: formState.valid,
    });
    this.props.dispatch({
      type: "FormButtons.pristine",
      payload: formState.pristine,
    });
    this.props.handleValues(formState.values);
  }

  checkboxParser = (checked, targetLabel, targetValue, fieldName, fieldsValues) => {
    let values = fieldsValues[fieldName] || {};
    let fieldValue = values[targetValue] || [];
    if (checked) {
      fieldValue.push(targetLabel);
    }else {
      fieldValue.splice(targetLabel, 1)
    }

    if (fieldValue.length === 0) {
      delete values[targetValue];
    } else {
      values[targetValue] = fieldValue;
    }
    return values;
  };

  updateModalState(event){
    let { fieldsStatus, fieldsValues } = this.state;
    let target = event.target;
    let value = $(target).val();
    let fieldName = target.name;

    if (target.type === "checkbox") {
      value = this.checkboxParser(target.checked, target.labels[0].textContent, value, fieldName, fieldsValues)
    }

    fieldsStatus[fieldName] = !!Object.values(value).length;

    let formStatus = !Object.values(fieldsStatus).includes(false);

    if (fieldsStatus[fieldName]) fieldsValues[fieldName]=value;
    this.handleFormStateUpdate({valid: formStatus, pristine: false, values: fieldsValues});

    this.setState({fieldsStatus: fieldsStatus, values: fieldsValues});
  }

  render() {
    if (Object.values(this.props.fieldsDataLoading).includes(true)) {
      return  <Loading className="export-spinner" withOverlay={false} small />;
    }

    return (
      <form onChange={this.updateModalState}>
        { this.props.children }
      </form>
    );
  }
}

LenovoForm.propTypes = {
  fieldsDataLoading: PropTypes.object.isRequired,
  dispatch: PropTypes.func.isRequired,
  handleValues: PropTypes.func.isRequired,
  children: PropTypes.oneOfType([
    PropTypes.array,
    PropTypes.object
  ]).isRequired,
};

export default connect()(LenovoForm);
