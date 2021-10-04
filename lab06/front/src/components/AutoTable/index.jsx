const AutoTable = ({ data }) => {
  const keys = Object.keys(data[0]);

  return (
    <table className="nes-table is-dark is-bordered">
      <thead>
        <th>
          {keys.map((key) => (
            <td key="key">{key}</td>
          ))}
        </th>
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
