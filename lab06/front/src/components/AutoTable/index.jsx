import { useEffect, useRef } from "react";

const AutoTable = ({ data }) => {
  const keys = Object.keys(data[0]);
  const ref = useRef();

  useEffect(() => {
    ref.current.scrollIntoView({
      behavior: "smooth",
    });
  });

  return (
    <table className="nes-table is-bordered" ref={ref}>
      <thead>
        <tr>
          {keys.map((key) => (
            <th key={key}>{key}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((row, i) => (
          <tr key={row.id || i}>
            {keys.map((key) => (
              <td key={key}>{row[key]}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default AutoTable;
