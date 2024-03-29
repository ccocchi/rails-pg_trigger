SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;

--
-- Name: comments_after_insert_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.comments_after_insert_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.comment_id;
    RETURN NULL;
END;
$$;

--
-- Name: comments_after_delete_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.comments_after_delete_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.comment_id;
    RETURN NULL;
END;
$$;

--
-- Name: comments comments_after_insert_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER comments_after_insert_tr AFTER INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION public.comments_after_insert_tr();

--
-- Name: comments comments_after_delete_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER comments_after_delete_tr AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.comments_after_delete_tr();

-- Ignored by scanner because it does not end with `_tr`

CREATE TRIGGER ignored_by_scanner AFTER DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.ignored_by_scanner();
