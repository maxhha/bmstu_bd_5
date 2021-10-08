import { useCallback, useEffect, useState } from "react";
import Header from "./components/Header";
import QueryCode from "./components/QueryCode";
import useFetch from "use-http";
import { API_URL } from "./constants";
import AutoTable from "./components/AutoTable";
import ParametersForm from "./components/ParametersForm";

function App() {
  const [query, setQuery] = useState();
  const [params, setParams] = useState([]);
  const [answer, setAnswer] = useState();

  const queryInfo = useFetch(
    `${API_URL}/${query}?query=1`,
    { cache: "no-cache" },
    [query]
  );
  const queryData = useFetch(API_URL, { cache: "no-cache" });

  const handleSelect = useCallback((query) => {
    setQuery(query);
    setAnswer(null);
    setParams(null);
  }, []);

  const handleClickLoad = useCallback(async () => {
    const resp = await queryData.get(
      query + "?params=" + JSON.stringify(params)
    );
    setAnswer(resp);
  }, [query, queryData.get, params]);

  useEffect(() => {
    const query = queryInfo.data?.query;
    if (query) {
      const n = new Set(query.match(/\$(\d)+/g)).size;
      setParams([...Array(n)].map(() => ""));
    } else {
      setParams(null);
    }
  }, [queryInfo.data?.query]);

  return (
    <div>
      <Header value={query} onSelect={handleSelect} />
      {query && queryInfo.loading && (
        <span className="nes-text is-disabled">Загружается...</span>
      )}
      {query && queryInfo.error && (
        <pre className="nes-text is-error">
          {queryInfo.error.message || JSON.stringify(queryInfo.error, null, 2)}
        </pre>
      )}
      {query && queryInfo.data?.query && (
        <QueryCode code={queryInfo.data.query} />
      )}
      {params?.length > 0 && (
        <ParametersForm params={params} onChange={setParams} />
      )}
      {query && queryInfo.data?.query && (
        <button
          className="nes-btn"
          disabled={queryInfo.data?.query == void 0 || queryData.loading}
          onClick={handleClickLoad}
        >
          Запросить
        </button>
      )}
      {answer?.length && <AutoTable data={answer} />}
      {answer?.length === 0 && <pre className="nes-text is-error">No data</pre>}
      {answer?.error && (
        <pre className="nes-text is-error">
          {answer.error.message ||
            (typeof answer.error === "string" && answer.error) ||
            JSON.stringify(answer.error, null, 2)}
        </pre>
      )}
    </div>
  );
}

export default App;
