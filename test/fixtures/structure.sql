SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;

--
-- Name: async_notions_after_delete_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.comments_after_insert_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.comment_id;
    RETURN NULL;
END;
$$;
