import Highlight from "react-highlight";
import useFetch from "use-http";
import { API_URL } from "../../constants";
import "./style.css";

const QueryCode = ({ queryName }) => {
  const { loading, error, data } = useFetch(
    `${API_URL}/${queryName}?query=1`,
    {},
    []
  );

  return (
    <div className="QueryCode">
      <span class="QueryCode__title">Запрос</span>
      {loading && (
        <span class="QueryCode__message nes-text is-disabled">
          Загружается...
        </span>
      )}
      {error && (
        <pre class="QueryCode__message nes-text is-error">
          {error.message || JSON.stringify(error, null, 2)}
        </pre>
      )}
      {data?.query && <Highlight classname="sql">{data.query}</Highlight>}
    </div>
  );
};

export default QueryCode;
