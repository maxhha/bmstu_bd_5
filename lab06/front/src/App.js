import { useCallback, useState } from "react";
import Header from "./components/Header";
import QueryCode from "./components/QueryCode";
import useFetch from "use-http";
import { API_URL } from "./constants";
import AutoTable from "./components/AutoTable";

function App() {
  const [query, setQuery] = useState();
  const [answer, setAnswer] = useState();

  const queryInfo = useFetch(`${API_URL}/${query}?query=1`, {}, [query]);
  const queryData = useFetch(API_URL);

  const handleSelect = useCallback((query) => {
    setQuery(query);
    setAnswer(null);
  }, []);

  const handleClickLoad = useCallback(async () => {
    const resp = await queryData.get(query);
    setAnswer(resp);
  }, [query, queryData.get]);

  return (
    <div>
      <Header value={query} onSelect={handleSelect} />
      {query && queryInfo.loading && (
        <span className="nes-text is-disabled">Загружается...</span>
      )}
      {query && queryInfo.error && (
        <pre class="nes-text is-error">
          {queryInfo.error.message || JSON.stringify(queryInfo.error, null, 2)}
        </pre>
      )}
      {query && queryInfo.data?.query && (
        <QueryCode code={queryInfo.data.query} />
      )}
      {query && queryInfo.data?.query && (
        <button
          class="nes-btn"
          disabled={queryInfo.data?.query == void 0 || queryData.loading}
          onClick={handleClickLoad}
        >
          Запросить
        </button>
      )}
      {answer && <AutoTable data={answer} />}
    </div>
  );
}

export default App;
