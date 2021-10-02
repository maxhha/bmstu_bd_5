import { useState } from "react";
import Header from "./components/Header";
import QueryCode from "./components/QueryCode";

function App() {
  const [query, setQuery] = useState();

  return (
    <div>
      <Header value={query} onSelect={setQuery} />
      {query && <QueryCode queryName={query} />}
    </div>
  );
}

export default App;
