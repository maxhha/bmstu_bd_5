import Highlight from "react-highlight";
import "./style.css";

const QueryCode = ({ code }) => {
  return (
    <>
      <div className="QueryCode">
        <span className="QueryCode__title">Запрос</span>
        {code && <Highlight className="sql">{code}</Highlight>}
      </div>
    </>
  );
};

export default QueryCode;
