import { useCallback, useState } from "react";
import Header from "./components/Header";
import QueryCode from "./components/QueryCode";
import useFetch from "use-http";
import { API_URL } from "./constants";

function App() {
  const [query, setQuery] = useState();
  const [answer, setAnswer] = useState();

  const queryInfo = useFetch(`${API_URL}/${query}?query=1`, {}, [query]);
  const { get } = useFetch(API_URL);

  const handleSelect = useCallback((query) => {
    setQuery(query);
    setAnswer(null);
  }, []);

  const handleClickLoad = useCallback(async () => {
    const resp = await get(query);
    setAnswer(resp);
  }, [query]);

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
          class="nes-button"
          disabled={queryInfo.data?.query == void 0}
          onClick={handleClickLoad}
        >
          Запросить
        </button>
      )}
      {answer && (
        <pre className="nes-text is-dark">
          {JSON.stringify(answer, null, 2)}
        </pre>
      )}
    </div>
  );
}

export default App;
