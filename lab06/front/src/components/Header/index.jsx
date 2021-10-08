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
          <option value="get_avg_n_reviews_per_book_owner">
            get avg n reviews per book owner
          </option>
          <option value="get_datconnlimit">get datconnlimit</option>
          <option value="get_age">get age</option>
          <option value="get_authors_rates">get authors rates</option>
          <option value="update_author_death_date">
            update author death date
          </option>
          <option value="current_database">current database</option>
          <option value="create_table">create table</option>
          <option value="insert_table">insert table</option>
          <option value="select_table">select table</option>
        </select>
      </div>
    </div>
  );
};

export default Header;
