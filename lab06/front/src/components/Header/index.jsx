import { useCallback } from "react";
import "./style.css";

const Header = ({ value, onSelect }) => {
  const handleChange = useCallback((event) => {
    const { value } = event.target;

    onSelect && onSelect(value);
  }, []);

  return (
    <div className="Header">
      <label htmlFor="header-select-query" className="Header__label">
        Меню
      </label>
      <div className="nes-select is-dark">
        <select
          required
          id="header-select-query"
          onChange={handleChange}
          value={value || ""}
        >
          <option value="" disabled hidden>
            Выберете запрос...
          </option>
          <option value="count_reviews">count reviews</option>
          <option value="get_books">get books</option>
        </select>
      </div>
    </div>
  );
};

export default Header;
