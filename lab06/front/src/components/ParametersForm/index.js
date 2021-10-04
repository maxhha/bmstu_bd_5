import { useCallback, useMemo, useState } from "react";
import "./style.css";

const ParametersForm = ({ params, onChange }) => {
  const handleChange = (event) => {
    const { name, value } = event.target;

    const params_ = [...params];
    params_[name] = value;

    onChange(params_);
  };

  return (
    <div className="ParametersForm">
      {params.map((val, i) => (
        <div className="nes-field is-dark ParametersForm__row" key={i}>
          <label
            className="ParametersForm__label"
            htmlFor={`parameter-${i}`}
          >{`$${i + 1}:`}</label>
          <input
            className="nes-input is-dark ParametersForm__input"
            required
            id={`parameter-${i}`}
            autoComplete="none"
            value={val}
            name={i}
            onChange={handleChange}
          />
        </div>
      ))}
    </div>
  );
};

export default ParametersForm;
