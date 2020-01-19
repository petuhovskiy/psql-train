--
-- PostgreSQL database dump
--

-- Dumped from database version 12.0 (Debian 12.0-2.pgdg100+1)
-- Dumped by pg_dump version 12.0 (Debian 12.0-2.pgdg100+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_country_restr(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_country_restr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF ( SELECT count(*)
        FROM (
            SELECT
            user_id,
            country_code,
            album_id,
            ( SELECT count(*)
                FROM albums_countries
                WHERE album_id = t.album_id AND country_code = u.country_code ) AS allowed
            FROM library l, tracks t, users u
            WHERE l.user_id = NEW.user_id AND l.track_id = NEW.track_id AND l.user_id = u.id AND l.track_id = t.id
        ) AS perms
        WHERE perms.allowed = 0) <> 0
    THEN
        RAISE EXCEPTION 'You are not allowed to listen this track';
    ELSE
 -- В зависимости от вида операции (встроенная переменная
 -- TG_OP) с таблицей возвратим либо старую (OLD), либо
 -- новую (NEW) версии строки таблицы.
    IF ( TG_OP = 'DELETE' ) THEN
    RETURN OLD;
    ELSIF ( TG_OP = 'UPDATE' ) THEN
    RETURN NEW;
    ELSIF ( TG_OP = 'INSERT' ) THEN
    RETURN NEW;
    END IF;
    RETURN NULL;
    END IF;
END;
$$;


ALTER FUNCTION public.check_country_restr() OWNER TO postgres;

--
-- Name: check_library_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_library_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF ( SELECT count(*)
        FROM library
        WHERE user_id = NEW.user_id) > 1000
    THEN
        RAISE EXCEPTION 'You have too many tracks';
    ELSE
 -- В зависимости от вида операции (встроенная переменная
 -- TG_OP) с таблицей возвратим либо старую (OLD), либо
 -- новую (NEW) версии строки таблицы.
    IF ( TG_OP = 'DELETE' ) THEN
    RETURN OLD;
    ELSIF ( TG_OP = 'UPDATE' ) THEN
    RETURN NEW;
    ELSIF ( TG_OP = 'INSERT' ) THEN
    RETURN NEW;
    END IF;
    RETURN NULL;
    END IF;
END;
$$;


ALTER FUNCTION public.check_library_limit() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: albums; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albums (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    label_id integer,
    artist_id integer,
    name text NOT NULL,
    released_at timestamp without time zone,
    discs_count integer DEFAULT 1,
    specs jsonb,
    CONSTRAINT albums_discs_count_check CHECK ((discs_count >= 1))
);


ALTER TABLE public.albums OWNER TO postgres;

--
-- Name: albums_countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.albums_countries (
    album_id integer NOT NULL,
    country_code character(2) NOT NULL
);


ALTER TABLE public.albums_countries OWNER TO postgres;

--
-- Name: albums_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.albums_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.albums_id_seq OWNER TO postgres;

--
-- Name: albums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;


--
-- Name: artists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.artists (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    specs jsonb
);


ALTER TABLE public.artists OWNER TO postgres;

--
-- Name: artists_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.artists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.artists_id_seq OWNER TO postgres;

--
-- Name: artists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.artists_id_seq OWNED BY public.artists.id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countries (
    id character(2) NOT NULL,
    name text,
    CONSTRAINT countries_id_check CHECK ((upper((id)::text) = (id)::text))
);


ALTER TABLE public.countries OWNER TO postgres;

--
-- Name: labels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.labels (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    founded_at timestamp without time zone,
    specs jsonb
);


ALTER TABLE public.labels OWNER TO postgres;

--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.labels_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.labels_id_seq OWNER TO postgres;

--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: library; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.library (
    user_id integer NOT NULL,
    track_id integer NOT NULL
);


ALTER TABLE public.library OWNER TO postgres;

--
-- Name: mediafiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mediafiles (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    seconds integer NOT NULL,
    CONSTRAINT mediafiles_seconds_check CHECK ((seconds >= 0))
);


ALTER TABLE public.mediafiles OWNER TO postgres;

--
-- Name: mediafiles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mediafiles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mediafiles_id_seq OWNER TO postgres;

--
-- Name: mediafiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mediafiles_id_seq OWNED BY public.mediafiles.id;


--
-- Name: tracks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tracks (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name text NOT NULL,
    album_id integer,
    disc_id integer DEFAULT 1,
    position_id integer,
    artist_id integer,
    mediafile_id integer NOT NULL,
    specs jsonb,
    CONSTRAINT tracks_disc_id_check CHECK ((disc_id >= 1)),
    CONSTRAINT tracks_position_id_check CHECK ((position_id >= 1))
);


ALTER TABLE public.tracks OWNER TO postgres;

--
-- Name: tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tracks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tracks_id_seq OWNER TO postgres;

--
-- Name: tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tracks_id_seq OWNED BY public.tracks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    first_name text,
    second_name text,
    email text,
    country_code character(2) NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: albums id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);


--
-- Name: artists id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artists ALTER COLUMN id SET DEFAULT nextval('public.artists_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: mediafiles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mediafiles ALTER COLUMN id SET DEFAULT nextval('public.mediafiles_id_seq'::regclass);


--
-- Name: tracks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks ALTER COLUMN id SET DEFAULT nextval('public.tracks_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: albums; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums (id, created_at, label_id, artist_id, name, released_at, discs_count, specs) FROM stdin;
1	2019-12-22 18:40:27.827977	8	3	Push The Sky Away	2013-02-15 00:00:00	2	{"Year": 2013, "Catno": "BS001V", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Blues Rock"], "Barcode": "5 055667 601768", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 29472"}
2	2019-12-22 18:40:27.827977	8	3	Skeleton Tree	2016-09-09 00:00:00	2	{"Year": 2016, "Catno": "BS009V", "Genres": ["Rock"], "Styles": ["Alternative Rock"], "Barcode": "5060454943846", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 29472"}
3	2019-12-22 18:40:27.827977	42	4	Make It Big	1984-01-01 00:00:00	2	{"Year": 1984, "Catno": "FC 39595", "Genres": ["Electronic", "Funk / Soul", "Pop"], "Styles": ["Synth-pop", "Soul"], "Barcode": "074643959513", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
4	2019-12-22 18:40:27.827977	9	5	Doggystyle	2001-05-01 00:00:00	4	{"Year": 2001, "Catno": "DRR 63002-1", "Genres": ["Hip Hop"], "Styles": ["Gangsta", "G-Funk"], "Barcode": "728706300216", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
5	2019-12-22 18:40:27.827977	81	7	Off The Wall	1979-08-10 00:00:00	2	{"Year": 1979, "Catno": "FE 35745", "Genres": ["Funk / Soul", "Pop"], "Styles": ["Disco", "Soul", "Ballad"], "Barcode": "074643574518", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
6	2019-12-22 18:40:27.827977	81	7	Bad	1987-09-01 00:00:00	2	{"Year": 1987, "Catno": "EPC 450290 1", "Genres": ["Electronic", "Rock", "Funk / Soul", "Pop"], "Styles": ["Pop Rock", "Funk", "Soul", "Ballad"], "Barcode": "5 099745 029013", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 0199"}
7	2019-12-22 18:40:27.827977	81	7	Thriller	1982-11-30 00:00:00	2	{"Year": 1982, "Catno": "QE 38112", "Genres": ["Funk / Soul", "Pop"], "Styles": ["Disco", "Soul"], "Barcode": "074643811217", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
8	2019-12-22 18:40:27.827977	53	8	Is This It	2001-10-09 00:00:00	2	{"Year": 2001, "Catno": "07863 68045-1", "Genres": ["Rock"], "Styles": ["Indie Rock", "Garage Rock", "Post-Punk"], "Barcode": "0 7863-68045-1 4", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
9	2019-12-22 18:40:27.827977	40	9	Blue Monday	1983-03-07 00:00:00	2	{"Year": 1983, "Catno": "FAC 73", "Genres": ["Electronic"], "Styles": ["Electro", "Synth-pop"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["12\\"", "45 RPM", "Single"]}]}
10	2019-12-22 18:40:27.827977	50	10	Songs In The Key Of Life	1976-09-28 00:00:00	6	{"Year": 1976, "Catno": "T13-340C2", "Genres": ["Jazz", "Funk / Soul"], "Styles": ["Soul", "Funk", "Fusion", "Jazz-Funk"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP"]}, {"qty": "1", "name": "Vinyl", "descriptions": ["7\\"", "33 ⅓ RPM", "EP"]}, {"qty": "1", "name": "All Media", "descriptions": ["Album"]}]}
11	2019-12-22 18:40:27.827977	60	11	Parallel Lines	1978-01-01 00:00:00	2	{"Year": 1978, "Catno": "CHR 1192", "Genres": ["Rock"], "Styles": ["New Wave", "Pop Rock", "Punk", "Disco"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
12	2019-12-22 18:40:27.827977	6	12	Fly Like An Eagle	1976-01-01 00:00:00	2	{"Year": 1976, "Catno": "ST-11497", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
13	2019-12-22 18:40:27.827977	7	15	Homework	1997-01-20 00:00:00	4	{"Year": 1997, "Catno": "V 2821", "Genres": ["Electronic"], "Styles": ["House", "Techno", "Disco", "Electro"], "Barcode": "724384260910", "Country": "UK & Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 3098"}
14	2019-12-22 18:40:27.827977	7	15	Discovery	2001-03-01 00:00:00	4	{"Year": 2001, "Catno": "V2940", "Genres": ["Electronic"], "Styles": ["House", "Disco"], "Barcode": "724381008812", "Country": "Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "03098"}
15	2019-12-22 18:40:27.827977	42	15	Random Access Memories	2013-05-17 00:00:00	4	{"Year": 2013, "Catno": "88883716861", "Genres": ["Electronic", "Funk / Soul", "Pop"], "Styles": ["Disco", "Funk", "Electro", "Synth-pop"], "Barcode": "8 88837 16861 8", "Country": "UK, Europe & US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC00162"}
16	2019-12-22 18:40:27.827977	39	16	Around The World In A Day	1985-01-01 00:00:00	2	{"Year": 1985, "Catno": "9 25286-1", "Genres": ["Rock", "Funk / Soul", "Pop"], "Styles": ["Pop Rock", "Dance-pop", "Funk", "Minneapolis Sound"], "Barcode": "075992528610", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
17	2019-12-22 18:40:27.827977	46	16	Purple Rain	1984-06-25 00:00:00	2	{"Year": 1984, "Catno": "25110-1", "Genres": ["Electronic", "Funk / Soul", "Pop", "Stage & Screen"], "Styles": ["Pop Rock", "Funk", "Soundtrack", "Synth-pop"], "Barcode": "075992511018", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
18	2019-12-22 18:40:27.827977	79	17	The King Of Limbs	2011-05-09 00:00:00	5	{"Year": 2011, "Catno": "TICK001S", "Genres": ["Electronic", "Rock"], "Styles": ["Experimental", "Alternative Rock"], "Barcode": "8 27565 05765 8", "Country": "UK", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["10\\"", "45 RPM", "Album"]}, {"qty": "1", "name": "CD", "descriptions": ["Album"]}, {"qty": "1", "name": "All Media", "descriptions": ["Limited Edition"]}]}
19	2019-12-22 18:40:27.827977	67	17	OK Computer OKNOTOK 1997 2017	2017-06-23 00:00:00	7	{"Year": 2017, "Catno": "XLLP868X", "Genres": ["Rock"], "Styles": ["Alternative Rock"], "Barcode": "634904086886", "Country": "UK & Europe", "Formats": [{"qty": "3", "name": "Vinyl", "descriptions": ["LP", "Album", "Limited Edition", "Reissue", "Remastered"]}], "LabelCode": "LC 05667"}
20	2019-12-22 18:40:27.827977	6	17	The Bends	2008-01-01 00:00:00	2	{"Year": 2008, "Catno": "7243 8 29626 1 8", "Genres": ["Rock"], "Styles": ["Alternative Rock"], "Barcode": "724382962618", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Limited Edition", "Reissue"]}]}
21	2019-12-22 18:40:27.827977	6	17	Kid A	2008-09-02 00:00:00	5	{"Year": 2008, "Catno": "5284821-A/B, 5284831-C/D", "Genres": ["Electronic", "Rock"], "Styles": ["Alternative Rock", "IDM", "Experimental"], "Barcode": "724352775316", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["10\\"", "33 ⅓ RPM", "Album", "Limited Edition", "Reissue"]}]}
22	2019-12-22 18:40:27.827977	67	17	A Moon Shaped Pool	2016-06-17 00:00:00	4	{"Year": 2016, "Catno": "XLLP790", "Genres": ["Electronic", "Rock"], "Styles": ["Art Rock", "Indie Rock"], "Barcode": "634904079017", "Country": "USA, Canada & Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
23	2019-12-22 18:40:27.827977	6	17	OK Computer	2008-01-01 00:00:00	5	{"Year": 2008, "Catno": "7243 8 55229 1 8", "Genres": ["Electronic", "Rock"], "Styles": ["Alternative Rock", "Experimental"], "Barcode": "724385522918", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Limited Edition", "Reissue"]}]}
24	2019-12-22 18:40:27.827977	32	17	In Rainbows	2008-01-01 00:00:00	2	{"Year": 2008, "Catno": "TBD0001", "Genres": ["Electronic", "Rock"], "Styles": ["Indie Rock", "Experimental"], "Barcode": "8 80882 16231 3", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
25	2019-12-22 18:40:27.827977	27	19	Back To Black	2006-01-01 00:00:00	2	{"Year": 2006, "Catno": "B0008994-01", "Genres": ["Jazz", "Funk / Soul", "Pop"], "Styles": ["Rhythm & Blues", "Soul"], "Barcode": "602517341296", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
26	2019-12-22 18:40:27.827977	10	24	Music Sounds Better With You	1998-01-01 00:00:00	1	{"Year": 1998, "Catno": "Roulé 305", "Genres": ["Electronic"], "Styles": ["House"], "Country": "France", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["12\\"", "33 ⅓ RPM", "Single Sided", "Single", "Etched"]}]}
27	2019-12-22 18:40:27.827977	52	25	All Things Must Pass	1970-11-27 00:00:00	6	{"Year": 1970, "Catno": "STCH 639", "Genres": ["Rock"], "Styles": ["Pop Rock", "Acoustic"], "Country": "US", "Formats": [{"qty": "3", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "Box Set", "descriptions": null}]}
28	2019-12-22 18:40:27.827977	6	26	Get The Knack	1979-01-01 00:00:00	2	{"Year": 1979, "Catno": "SO-11948", "Genres": ["Rock"], "Styles": ["Pop Rock", "Power Pop"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
29	2019-12-22 18:40:27.827977	6	27	Stranger In Town	1978-05-15 00:00:00	2	{"Year": 1978, "Catno": "SW-11698", "Genres": ["Rock"], "Styles": ["Rock & Roll", "Soft Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
30	2019-12-22 18:40:27.827977	30	28	Disintegration	2010-06-15 00:00:00	4	{"Year": 2010, "Catno": "R1 523284", "Genres": ["Rock"], "Styles": ["Alternative Rock", "New Wave"], "Barcode": "081227981693", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
31	2019-12-22 18:40:27.827977	60	30	Sports	1983-09-15 00:00:00	2	{"Year": 1983, "Catno": "FV 41412", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Barcode": "044114141211", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
32	2019-12-22 18:40:27.827977	67	31	XX	2009-10-20 00:00:00	2	{"Year": 2009, "Catno": "XL LP 450", "Genres": ["Electronic", "Rock"], "Styles": ["Indie Rock"], "Barcode": "6 34904 04501 2", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
33	2019-12-22 18:40:27.827977	81	32	Ten	2009-01-01 00:00:00	5	{"Year": 2009, "Catno": "88697413021", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Grunge"], "Barcode": "88697413021-S1", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Remastered", "Repress"]}]}
34	2019-12-22 18:40:27.827977	46	34	Tango In The Night	1987-01-01 00:00:00	2	{"Year": 1987, "Catno": "WX 65", "Genres": ["Rock", "Pop"], "Styles": ["Pop Rock", "Classic Rock"], "Barcode": "07599254711", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 0392"}
35	2019-12-22 18:40:27.827977	46	34	Tusk	1979-01-01 00:00:00	4	{"Year": 1979, "Catno": "2HS 3350", "Genres": ["Rock"], "Styles": ["Pop Rock", "AOR"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
36	2019-12-22 18:40:27.827977	46	34	Rumours	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "BSK 3010", "Genres": ["Rock"], "Styles": ["Soft Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
37	2019-12-22 18:40:27.827977	70	35	Led Zeppelin III	2014-06-02 00:00:00	2	{"Year": 2014, "Catno": "8122796576", "Genres": ["Rock"], "Styles": ["Classic Rock", "Hard Rock"], "Barcode": "081227965761", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
38	2019-12-22 18:40:27.827977	70	35	Untitled 	2014-10-24 00:00:00	2	{"Year": 2014, "Catno": "8122-79657-7", "Genres": ["Rock"], "Styles": ["Hard Rock", "Classic Rock", "Blues Rock"], "Barcode": "081227965778", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered", "Stereo"]}]}
39	2019-12-22 18:40:27.827977	70	35	Led Zeppelin	2014-06-02 00:00:00	2	{"Year": 2014, "Catno": "8122796641", "Genres": ["Rock"], "Styles": ["Blues Rock", "Hard Rock"], "Barcode": "081227966416", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
40	2019-12-22 18:40:27.827977	70	35	Untitled	2014-10-27 00:00:00	2	{"Year": 2014, "Catno": "R1-535340", "Genres": ["Rock"], "Styles": ["Hard Rock", "Blues Rock"], "Barcode": "081227965778", "Country": "USA & Canada", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
41	2019-12-22 18:40:27.827977	81	36	The Money Store	2012-04-21 00:00:00	2	{"Year": 2012, "Catno": "88691963511", "Genres": ["Electronic", "Hip Hop"], "Styles": ["Experimental", "Hardcore Hip-Hop"], "Barcode": "886919635119", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
42	2019-12-22 18:40:27.827977	47	37	Doolittle	2004-09-15 00:00:00	2	{"Year": 2004, "Catno": "CAD 905", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "6 5263709051 2", "Country": "UK & US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
43	2019-12-22 18:40:27.827977	25	38	Merriweather Post Pavilion	2009-01-06 00:00:00	4	{"Year": 2009, "Catno": "DNO 219", "Genres": ["Electronic", "Rock", "Funk / Soul"], "Styles": ["Indie Rock", "Experimental", "Psychedelic"], "Barcode": "801390021916", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Deluxe Edition"]}]}
44	2019-12-22 18:40:27.827977	7	39	So	1986-01-01 00:00:00	2	{"Year": 1986, "Catno": "207 587", "Genres": ["Electronic", "Rock", "Pop"], "Styles": ["Pop Rock", "Synth-pop"], "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 3098"}
45	2019-12-22 18:40:27.827977	65	42	Carrie & Lowell	2015-03-31 00:00:00	2	{"Year": 2015, "Catno": "AKR099", "Genres": ["Folk, World, & Country"], "Barcode": "656605609911", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
46	2019-12-22 18:40:27.827977	42	43	Escape	1981-01-01 00:00:00	2	{"Year": 1981, "Catno": "TC 37408", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Barcode": "0 7464-37408-1", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
47	2019-12-22 18:40:27.827977	70	44	4	1981-01-01 00:00:00	2	{"Year": 1981, "Catno": "SD 16999", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
48	2019-12-22 18:40:27.827977	45	48	Greatest Hits	1974-01-01 00:00:00	2	{"Year": 1974, "Catno": "MCA 2128", "Genres": ["Rock", "Pop"], "Styles": ["Pop Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
49	2019-12-22 18:40:27.827977	45	48	Goodbye Yellow Brick Road	1973-01-01 00:00:00	4	{"Year": 1973, "Catno": "MCA2-10003", "Genres": ["Rock"], "Styles": ["Pop Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
50	2019-12-22 18:40:27.827977	21	49	Appetite For Destruction	2015-04-01 00:00:00	3	{"Year": 2015, "Catno": "00720642414811", "Genres": ["Rock"], "Styles": ["Hard Rock", "Heavy Metal"], "Barcode": "720642414811", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
51	2019-12-22 18:40:27.827977	29	50	Let's Dance	1983-01-01 00:00:00	2	{"Year": 1983, "Catno": "1C 064-400 165", "Genres": ["Electronic", "Rock"], "Styles": ["Pop Rock", "New Wave"], "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 5717"}
52	2019-12-22 18:40:27.827977	58	50	Hunky Dory	2016-02-26 00:00:00	2	{"Year": 2016, "Catno": "0825646289448", "Genres": ["Rock"], "Styles": ["Glam", "Pop Rock"], "Barcode": "825646289448", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}], "LabelCode": "LC30419"}
53	2019-12-22 18:40:27.827977	24	50	★ (Blackstar)	2016-01-08 00:00:00	2	{"Year": 2016, "Catno": "88875173871", "Genres": ["Electronic", "Jazz", "Rock"], "Styles": ["Art Rock", "Experimental", "Jazz-Rock", "Prog Rock", "Glam"], "Barcode": "888751738713", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC00162"}
54	2019-12-22 18:40:27.827977	58	50	The Rise And Fall Of Ziggy Stardust And The Spiders From Mars	2016-02-26 00:00:00	2	{"Year": 2016, "Catno": "DB69734", "Genres": ["Rock"], "Styles": ["Glam", "Classic Rock", "Art Rock"], "Barcode": "825646287376", "Country": "UK, Europe & US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered", "Repress"]}], "LabelCode": "LC30419"}
55	2019-12-22 18:40:27.827977	26	51	Star Wars	1977-01-01 00:00:00	4	{"Year": 1977, "Catno": "2T-541", "Genres": ["Classical", "Stage & Screen"], "Styles": ["Soundtrack", "Score", "Neo-Romantic"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
56	2019-12-22 18:40:27.827977	42	52	Illmatic	2006-01-01 00:00:00	3	{"Year": 2006, "Catno": "475959 1", "Genres": ["Hip Hop"], "Styles": ["Conscious"], "Barcode": "5099747595912", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}], "LabelCode": "LC 0162"}
57	2019-12-22 18:40:27.827977	4	53	The Grand Illusion	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "SP-4637", "Genres": ["Rock"], "Styles": ["Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
58	2019-12-22 18:40:27.827977	42	54	Stardust	1978-04-01 00:00:00	2	{"Year": 1978, "Catno": "JC 35305", "Genres": ["Pop", "Folk, World, & Country"], "Styles": ["Vocal"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
59	2019-12-22 18:40:27.827977	61	58	Saturday Night Fever (The Original Movie Sound Track)	1977-01-01 00:00:00	4	{"Year": 1977, "Catno": "RS-2-4001", "Genres": ["Electronic", "Funk / Soul", "Pop", "Stage & Screen"], "Styles": ["Soundtrack", "Disco"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Compilation", "Repress"]}]}
60	2019-12-22 18:40:27.827977	15	58	Guardians Of The Galaxy	2014-09-16 00:00:00	5	{"Year": 2014, "Catno": "D002054901", "Genres": ["Rock", "Funk / Soul", "Stage & Screen"], "Styles": ["Soundtrack", "Classic Rock", "Pop Rock", "Soul"], "Barcode": "0 50087 31088 2", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}, {"qty": "1", "name": "Vinyl", "descriptions": ["LP"]}, {"qty": "1", "name": "All Media", "descriptions": ["Deluxe Edition"]}]}
61	2019-12-22 18:40:27.827977	45	58	Pulp Fiction (Music From The Motion Picture)	2008-12-09 00:00:00	2	{"Year": 2008, "Catno": "0008811110314", "Genres": ["Rock", "Funk / Soul", "Non-Music", "Stage & Screen"], "Styles": ["Surf", "Rock & Roll", "Dialogue", "Soul", "Soundtrack", "Funk"], "Barcode": "008811110314", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation", "Reissue", "Remastered"]}], "LabelCode": "LC 01056"}
62	2019-12-22 18:40:27.827977	61	58	Grease (The Original Soundtrack From The Motion Picture)	1978-01-01 00:00:00	4	{"Year": 1978, "Catno": "RS-2-4002", "Genres": ["Rock", "Stage & Screen"], "Styles": ["Soundtrack", "Rock & Roll", "Pop Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
129	2019-12-22 18:40:27.827977	42	127	The Wall	1979-01-01 00:00:00	4	{"Year": 1979, "Catno": "PC2 36183", "Genres": ["Rock"], "Styles": ["Prog Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
63	2019-12-22 18:40:27.827977	72	59	In The Court Of The Crimson King	2010-10-18 00:00:00	2	{"Year": 2010, "Catno": "KCLP1", "Genres": ["Rock"], "Styles": ["Prog Rock"], "Barcode": "633367911117", "Country": "UK & US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
64	2019-12-22 18:40:27.827977	70	60	Back In Black	1980-01-01 00:00:00	2	{"Year": 1980, "Catno": "SD 16018", "Genres": ["Rock", "Blues"], "Styles": ["Hard Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
65	2019-12-22 18:40:27.827977	77	65	Waiting For The Sun	1968-07-01 00:00:00	2	{"Year": 1968, "Catno": "EKS-74024", "Genres": ["Rock"], "Styles": ["Blues Rock", "Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
66	2019-12-22 18:40:27.827977	77	65	L.A. Woman	1971-01-01 00:00:00	2	{"Year": 1971, "Catno": "EKS-75011", "Genres": ["Rock"], "Styles": ["Blues Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
67	2019-12-22 18:40:27.827977	77	65	The Doors	1967-01-01 00:00:00	2	{"Year": 1967, "Catno": "EKS-74007", "Genres": ["Rock"], "Styles": ["Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Repress", "Stereo"]}]}
68	2019-12-22 18:40:27.827977	11	66	Damn The Torpedoes	1979-10-19 00:00:00	2	{"Year": 1979, "Catno": "MCA-5105", "Genres": ["Rock"], "Styles": ["Soft Rock", "Hard Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
69	2019-12-22 18:40:27.827977	6	67	Paul's Boutique	2009-02-10 00:00:00	2	{"Year": 2009, "Catno": "509996 93300 18", "Genres": ["Hip Hop"], "Styles": ["Hardcore Hip-Hop", "Boom Bap"], "Barcode": "5099969330018", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Remastered", "Reissue"]}]}
70	2019-12-22 18:40:27.827977	44	71	Bella Donna	1981-01-01 00:00:00	2	{"Year": 1981, "Catno": "MR 38-139", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
71	2019-12-22 18:40:27.827977	78	72	Running On Empty	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "6E-113", "Genres": ["Rock"], "Styles": ["Pop Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
72	2019-12-22 18:40:27.827977	42	79	Blood On The Tracks	1975-01-20 00:00:00	2	{"Year": 1975, "Catno": "PC 33235", "Genres": ["Rock"], "Styles": ["Folk Rock", "Acoustic", "Ballad"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
73	2019-12-22 18:40:27.827977	42	79	Desire	1976-01-05 00:00:00	2	{"Year": 1976, "Catno": "PC 33893", "Genres": ["Rock"], "Styles": ["Folk Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
74	2019-12-22 18:40:27.827977	42	79	Nashville Skyline	1969-04-09 00:00:00	2	{"Year": 1969, "Catno": "KCS 9825", "Genres": ["Rock"], "Styles": ["Folk Rock", "Country Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
75	2019-12-22 18:40:27.827977	34	80	True Blue	1986-01-01 00:00:00	2	{"Year": 1986, "Catno": "925 442-1", "Genres": ["Electronic", "Pop"], "Styles": ["Dance-pop", "Pop Rock"], "Barcode": "075992544214", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 3228"}
76	2019-12-22 18:40:27.827977	70	81	Briefcase Full Of Blues	1978-01-01 00:00:00	2	{"Year": 1978, "Catno": "SD 19217", "Genres": ["Blues"], "Styles": ["Chicago Blues"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
77	2019-12-22 18:40:27.827977	4	83	Zenyatta Mondatta	1980-10-03 00:00:00	2	{"Year": 1980, "Catno": "AMLH 64831", "Genres": ["Rock"], "Styles": ["New Wave"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
78	2019-12-22 18:40:27.827977	4	83	Outlandos D'Amour	1978-01-01 00:00:00	2	{"Year": 1978, "Catno": "AMLH 68502", "Genres": ["Rock"], "Styles": ["New Wave"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
79	2019-12-22 18:40:27.827977	4	83	Synchronicity	1983-06-07 00:00:00	2	{"Year": 1983, "Catno": "SP-3735", "Genres": ["Rock"], "Styles": ["Alternative Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
80	2019-12-22 18:40:27.827977	4	83	Ghost In The Machine	1981-10-02 00:00:00	2	{"Year": 1981, "Catno": "SP-3730", "Genres": ["Rock"], "Styles": ["Art Rock", "Pop Rock", "Prog Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
81	2019-12-22 18:40:27.827977	42	84	Santana	1969-08-01 00:00:00	2	{"Year": 1969, "Catno": "CS 9781", "Genres": ["Rock", "Latin", "Funk / Soul"], "Styles": ["Afro-Cuban", "Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
82	2019-12-22 18:40:27.827977	77	85	Picture Book	1985-10-14 00:00:00	2	{"Year": 1985, "Catno": "EKT 27", "Genres": ["Rock", "Funk / Soul", "Pop"], "Styles": ["Rhythm & Blues", "Soul", "Ballad"], "Barcode": "075596045216", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 0192"}
83	2019-12-22 18:40:27.827977	4	86	Frampton Comes Alive!	1976-01-01 00:00:00	4	{"Year": 1976, "Catno": "SP-3703", "Genres": ["Rock"], "Styles": ["Rock & Roll", "Pop Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
84	2019-12-22 18:40:27.827977	42	87	Rocks	1976-01-01 00:00:00	2	{"Year": 1976, "Catno": "PC 34165", "Genres": ["Rock"], "Styles": ["Hard Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
85	2019-12-22 18:40:27.827977	42	87	Toys In The Attic	1975-01-01 00:00:00	2	{"Year": 1975, "Catno": "PC 33479", "Genres": ["Rock"], "Styles": ["Hard Rock", "Classic Rock", "Blues Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
86	2019-12-22 18:40:27.827977	12	88	Lost In The Dream	2014-03-18 00:00:00	4	{"Year": 2014, "Catno": "SC310", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "6 56605 03101 9", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 29278"}
87	2019-12-22 18:40:27.827977	81	89	Don't Look Back	1978-08-02 00:00:00	2	{"Year": 1978, "Catno": "FE 35050", "Genres": ["Rock"], "Styles": ["Hard Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
88	2019-12-22 18:40:27.827977	81	89	Boston	1976-01-01 00:00:00	2	{"Year": 1976, "Catno": "JE 34188", "Genres": ["Rock"], "Styles": ["Hard Rock", "Pop Rock", "Arena Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
89	2019-12-22 18:40:27.827977	28	90	'Allelujah! Don't Bend Ascend	2012-10-15 00:00:00	4	{"Year": 2012, "Catno": "CST081-1", "Genres": ["Electronic", "Rock"], "Styles": ["Post Rock", "Drone"], "Barcode": "666561008116", "Country": "Canada", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP"]}, {"qty": "1", "name": "Vinyl", "descriptions": ["7\\"", "45 RPM"]}, {"qty": "1", "name": "All Media", "descriptions": ["Album"]}]}
90	2019-12-22 18:40:27.827977	28	90	Lift Your Skinny Fists Like Antennas To Heaven	2000-10-09 00:00:00	1	{"Year": 2000, "Catno": "cst012", "Genres": ["Rock"], "Styles": ["Post Rock", "Experimental"], "Barcode": "666561001216", "Country": "Canada", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
91	2019-12-22 18:40:27.827977	71	92	Syro	2014-09-19 00:00:00	6	{"Year": 2014, "Catno": "WARPLP247", "Genres": ["Electronic"], "Styles": ["Breakbeat", "IDM", "Downtempo"], "Barcode": "801061024710", "Country": "Europe", "Formats": [{"qty": "3", "name": "Vinyl", "descriptions": ["12\\"", "33 ⅓ RPM", "Album"]}], "LabelCode": "LC02070"}
92	2019-12-22 18:40:27.827977	46	93	Demon Days	2017-04-01 00:00:00	4	{"Year": 2017, "Catno": "559329-1", "Genres": ["Electronic", "Hip Hop", "Rock", "Pop"], "Styles": ["Leftfield", "Trip Hop", "Lo-Fi", "Pop Rap", "Brit Pop", "Downtempo"], "Barcode": "1 90295 85999 2", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Club Edition", "Reissue", "Remastered"]}]}
93	2019-12-22 18:40:27.827977	58	93	Plastic Beach	2010-09-13 00:00:00	4	{"Year": 2010, "Catno": "5099962616614", "Genres": ["Electronic", "Hip Hop", "Pop"], "Styles": ["Leftfield", "Electro", "Hip Hop", "Synth-pop"], "Barcode": "5099962616614", "Country": "UK", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 0299"}
94	2019-12-22 18:40:27.827977	77	94	News Of The World	1977-11-01 00:00:00	2	{"Year": 1977, "Catno": "6E-112", "Genres": ["Rock"], "Styles": ["Hard Rock", "Pop Rock", "Classic Rock", "Glam"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
95	2019-12-22 18:40:27.827977	62	94	A Night At The Opera	1975-11-21 00:00:00	2	{"Year": 1975, "Catno": "EMTC 103", "Genres": ["Rock"], "Styles": ["Hard Rock", "Prog Rock", "Classic Rock", "Pop Rock"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
96	2019-12-22 18:40:27.827977	77	95	Tracy Chapman	1988-01-01 00:00:00	2	{"Year": 1988, "Catno": "960 774-1", "Genres": ["Rock"], "Styles": ["Folk Rock"], "Barcode": "0 7559-60774-1 5", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC 0192"}
97	2019-12-22 18:40:27.827977	81	96	Bat Out Of Hell	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "PE 34974", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
98	2019-12-22 18:40:27.827977	42	97	52nd Street	1978-01-01 00:00:00	2	{"Year": 1978, "Catno": "FC 35609", "Genres": ["Rock"], "Styles": ["Pop Rock", "Soft Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
99	2019-12-22 18:40:27.827977	42	97	An Innocent Man	1983-01-01 00:00:00	2	{"Year": 1983, "Catno": "QC 38837", "Genres": ["Rock"], "Styles": ["Rock & Roll", "Pop Rock"], "Barcode": "074643883719", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
100	2019-12-22 18:40:27.827977	42	97	Glass Houses	1980-01-01 00:00:00	2	{"Year": 1980, "Catno": "FC 36384", "Genres": ["Rock", "Pop"], "Styles": ["Pop Rock", "Rock & Roll"], "Barcode": "074643638418", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
101	2019-12-22 18:40:27.827977	42	97	The Stranger	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "JC 34987", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
102	2019-12-22 18:40:27.827977	70	98	Déjà Vu	1970-03-11 00:00:00	2	{"Year": 1970, "Catno": "SD 7200", "Genres": ["Rock"], "Styles": ["Folk Rock", "Country Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
103	2019-12-22 18:40:27.827977	66	99	Bon Iver, Bon Iver	2011-06-21 00:00:00	2	{"Year": 2011, "Catno": "JAG135", "Genres": ["Rock"], "Styles": ["Folk Rock", "Indie Rock"], "Barcode": "656605213514", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
104	2019-12-22 18:40:27.827977	66	99	For Emma, Forever Ago	2008-02-19 00:00:00	2	{"Year": 2008, "Catno": "JAG115", "Genres": ["Rock", "Folk, World, & Country"], "Styles": ["Folk Rock", "Acoustic", "Indie Rock", "Folk"], "Barcode": "656605211510", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
105	2019-12-22 18:40:27.827977	67	101	21	2011-01-21 00:00:00	2	{"Year": 2011, "Catno": "XLLP 520", "Genres": ["Jazz", "Funk / Soul", "Blues", "Pop"], "Styles": ["Soul-Jazz", "Acoustic", "Piano Blues", "Neo Soul"], "Barcode": "6 34904 05201 0", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
106	2019-12-22 18:40:27.827977	68	102	Twin Peaks	2016-08-10 00:00:00	2	{"Year": 2016, "Catno": "DW50", "Genres": ["Electronic", "Jazz", "Stage & Screen"], "Styles": ["Soundtrack", "Score", "Ambient"], "Barcode": "826853874212", "Country": "USA & Canada", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
107	2019-12-22 18:40:27.827977	4	107	"...Famous Last Words..."	1982-01-01 00:00:00	2	{"Year": 1982, "Catno": "AMLK 63732", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC -0485"}
108	2019-12-22 18:40:27.827977	4	107	Breakfast In America	1979-01-01 00:00:00	2	{"Year": 1979, "Catno": "SP-3708", "Genres": ["Rock"], "Styles": ["Art Rock", "Pop Rock", "Classic Rock"], "Barcode": "0 7502=13708-1", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
109	2019-12-22 18:40:27.827977	21	108	MTV Unplugged In New York	2008-01-01 00:00:00	2	{"Year": 2008, "Catno": "0720642472712", "Genres": ["Rock", "Blues"], "Styles": ["Acoustic", "Grunge"], "Barcode": "7 20642 47271 2", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Repress"]}], "LabelCode": "LC 07266"}
110	2019-12-22 18:40:27.827977	43	108	Nevermind	2015-06-04 00:00:00	2	{"Year": 2015, "Catno": "424 425-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Grunge"], "Barcode": "0 720642 442517", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}], "LabelCode": "LC 07266"}
111	2019-12-22 18:40:27.827977	81	109	Diamond Life	1984-01-01 00:00:00	2	{"Year": 1984, "Catno": "EPC 26044", "Genres": ["Jazz", "Funk / Soul"], "Styles": ["Soul"], "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC0199"}
112	2019-12-22 18:40:27.827977	48	110	Run The Jewels 3	2017-01-13 00:00:00	4	{"Year": 2017, "Catno": "RTJ003LP", "Genres": ["Hip Hop"], "Styles": ["Hardcore Hip-Hop"], "Barcode": "853895007025", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
113	2019-12-22 18:40:27.827977	30	111	Currents	2015-07-17 00:00:00	4	{"Year": 2015, "Catno": "473067-7", "Genres": ["Electronic", "Rock"], "Styles": ["Indie Rock", "Psychedelic Rock", "Synth-pop"], "Barcode": "6 02547 30677 7", "Country": "Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
114	2019-12-22 18:40:27.827977	35	111	Lonerism	2012-10-09 00:00:00	4	{"Year": 2012, "Catno": "MODVL161", "Genres": ["Rock"], "Styles": ["Psychedelic Rock"], "Barcode": "6 02537 11996 7", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
115	2019-12-22 18:40:27.827977	42	112	Head Hunters	1973-01-01 00:00:00	2	{"Year": 1973, "Catno": "KC 32731", "Genres": ["Electronic", "Jazz"], "Styles": ["Jazz-Funk"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
116	2019-12-22 18:40:27.827977	69	113	I Robot	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "AL 7002", "Genres": ["Rock"], "Styles": ["Prog Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
117	2019-12-22 18:40:27.827977	53	115	Enter The Wu-Tang (36 Chambers)	1993-11-09 00:00:00	3	{"Year": 1993, "Catno": "07863 66336-1", "Genres": ["Hip Hop"], "Styles": ["Hardcore Hip-Hop"], "Barcode": "078636633619", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
118	2019-12-22 18:40:27.827977	55	116	The Epic	2015-10-02 00:00:00	7	{"Year": 2015, "Catno": "BF050", "Genres": ["Jazz", "Funk / Soul"], "Styles": ["Fusion", "Contemporary Jazz", "Psychedelic", "Soul-Jazz"], "Barcode": "5054429002300", "Country": "USA & Europe", "Formats": [{"qty": "3", "name": "Vinyl", "descriptions": ["LP"]}, {"qty": "1", "name": "Box Set", "descriptions": ["Album"]}]}
119	2019-12-22 18:40:27.827977	7	117	Siamese Dream	2011-11-29 00:00:00	4	{"Year": 2011, "Catno": "50999 67928 9 10", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Grunge"], "Barcode": "5 099967 928910", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered", "Repress"]}]}
120	2019-12-22 18:40:27.827977	46	120	Californication	\N	4	{"Catno": "9362-47386-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Funk Metal"], "Barcode": "093624738619", "Country": "Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Repress"]}], "LabelCode": "LC 00392"}
121	2019-12-22 18:40:27.827977	73	121	Into The Wild	2010-10-07 00:00:00	2	{"Year": 2010, "Catno": "MOVLP166", "Genres": ["Rock", "Stage & Screen"], "Styles": ["Folk Rock", "Acoustic", "Soundtrack"], "Barcode": "6174718980405", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
122	2019-12-22 18:40:27.827977	51	123	Rust Never Sleeps	1979-01-01 00:00:00	2	{"Year": 1979, "Catno": "HS 2295", "Genres": ["Rock"], "Styles": ["Acoustic", "Folk Rock", "Hard Rock", "Classic Rock", "Arena Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
123	2019-12-22 18:40:27.827977	47	124	Trouble Will Find Me	2013-05-21 00:00:00	4	{"Year": 2013, "Catno": "CAD3315", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "652637331516", "Country": "UK, Europe & US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
124	2019-12-22 18:40:27.827977	42	125	Chicago IX Chicago's Greatest Hits	1975-11-10 00:00:00	2	{"Year": 1975, "Catno": "PC 33900", "Genres": ["Rock"], "Styles": ["Soft Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
125	2019-12-22 18:40:27.827977	46	126	History · America's Greatest Hits	1975-01-01 00:00:00	2	{"Year": 1975, "Catno": "BS 2894", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
126	2019-12-22 18:40:27.827977	57	127	Meddle	1971-10-30 00:00:00	2	{"Year": 1971, "Catno": "SMAS-832", "Genres": ["Rock"], "Styles": ["Psychedelic Rock", "Prog Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
127	2019-12-22 18:40:27.827977	42	127	Animals	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "JC 34474", "Genres": ["Rock"], "Styles": ["Prog Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
128	2019-12-22 18:40:27.827977	57	127	Wish You Were Here	1975-09-15 00:00:00	3	{"Year": 1975, "Catno": "SHVL 814", "Genres": ["Rock"], "Styles": ["Prog Rock"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
130	2019-12-22 18:40:27.827977	57	127	The Dark Side Of The Moon	1973-01-01 00:00:00	2	{"Year": 1973, "Catno": "SMAS-11163", "Genres": ["Rock"], "Styles": ["Prog Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
131	2019-12-22 18:40:27.827977	42	128	Bookends	1968-01-01 00:00:00	2	{"Year": 1968, "Catno": "KCS 9529", "Genres": ["Rock", "Pop"], "Styles": ["Folk Rock", "Soft Rock", "Pop Rock", "Vocal"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
132	2019-12-22 18:40:27.827977	42	128	Simon And Garfunkel's Greatest Hits	1972-06-01 00:00:00	2	{"Year": 1972, "Catno": "KC 31350", "Genres": ["Rock"], "Styles": ["Folk Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
133	2019-12-22 18:40:27.827977	42	128	Bridge Over Troubled Water	1970-01-26 00:00:00	2	{"Year": 1970, "Catno": "KCS 9914", "Genres": ["Pop"], "Styles": ["Folk Rock", "Pop Rock", "Soft Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
134	2019-12-22 18:40:27.827977	42	129	Kind Of Blue	2010-01-01 00:00:00	2	{"Year": 2010, "Catno": "88697680571", "Genres": ["Jazz"], "Styles": ["Modal", "Cool Jazz"], "Barcode": "886976805715", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
135	2019-12-22 18:40:27.827977	38	130	Brothers And Sisters	1973-01-01 00:00:00	2	{"Year": 1973, "Catno": "CP 0111", "Genres": ["Rock", "Blues"], "Styles": ["Blues Rock", "Southern Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
136	2019-12-22 18:40:27.827977	14	131	Yankee Hotel Foxtrot	2008-01-01 00:00:00	5	{"Year": 2008, "Catno": "79669-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Country Rock", "Indie Rock"], "Barcode": "075597966916", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}, {"qty": "1", "name": "CD", "descriptions": ["Album", "Enhanced"]}]}
137	2019-12-22 18:40:27.827977	64	132	Elephant	2013-08-27 00:00:00	4	{"Year": 2013, "Catno": "TMR200", "Genres": ["Rock"], "Styles": ["Rock & Roll", "Indie Rock", "Garage Rock", "Punk"], "Barcode": "093624944003", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Repress"]}]}
138	2019-12-22 18:40:27.827977	36	135	Tapestry	1971-03-01 00:00:00	2	{"Year": 1971, "Catno": "ODE SP 77009", "Genres": ["Rock", "Pop"], "Styles": ["Pop Rock", "Vocal"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
139	2019-12-22 18:40:27.827977	52	136	Band On The Run	1973-01-01 00:00:00	2	{"Year": 1973, "Catno": "SO-3415", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
140	2019-12-22 18:40:27.827977	42	137	Dirt	2009-11-23 00:00:00	2	{"Year": 2009, "Catno": "MOVLP037", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Hard Rock", "Grunge"], "Barcode": "886973529010", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}], "LabelCode": "LC 02604"}
141	2019-12-22 18:40:27.827977	46	138	Van Halen	1978-04-01 00:00:00	2	{"Year": 1978, "Catno": "BSK 3075", "Genres": ["Rock"], "Styles": ["Hard Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
142	2019-12-22 18:40:27.827977	46	138	Van Halen II	1979-01-01 00:00:00	2	{"Year": 1979, "Catno": "HS 3312", "Genres": ["Rock"], "Styles": ["Hard Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
143	2019-12-22 18:40:27.827977	46	138	1984	1984-01-09 00:00:00	2	{"Year": 1984, "Catno": "1-23985", "Genres": ["Rock"], "Styles": ["Hard Rock"], "Barcode": "0 7599-23985-1", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
144	2019-12-22 18:40:27.827977	16	139	Aja	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "AA 1006", "Genres": ["Jazz", "Rock"], "Styles": ["Jazz-Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
145	2019-12-22 18:40:27.827977	45	139	Gaucho	1980-01-01 00:00:00	2	{"Year": 1980, "Catno": "MCA-6102", "Genres": ["Jazz", "Rock"], "Styles": ["Pop Rock", "Classic Rock", "Jazz-Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
146	2019-12-22 18:40:27.827977	75	140	Everything All The Time	2006-03-21 00:00:00	2	{"Year": 2006, "Catno": "SP 690", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "098787069013", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
147	2019-12-22 18:40:27.827977	4	141	Tea For The Tillerman	1970-11-01 00:00:00	2	{"Year": 1970, "Catno": "SP-4280", "Genres": ["Rock"], "Styles": ["Folk Rock", "Acoustic", "Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
148	2019-12-22 18:40:27.827977	78	142	Their Greatest Hits 1971-1975	1976-01-01 00:00:00	2	{"Year": 1976, "Catno": "7E-1052", "Genres": ["Rock"], "Styles": ["Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Compilation", "Reissue"]}]}
149	2019-12-22 18:40:27.827977	78	142	Hotel California	1976-01-01 00:00:00	2	{"Year": 1976, "Catno": "7E-1084", "Genres": ["Rock"], "Styles": ["Classic Rock", "Country Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
150	2019-12-22 18:40:27.827977	42	143	Pearl	1971-01-01 00:00:00	2	{"Year": 1971, "Catno": "KC 30322", "Genres": ["Rock"], "Styles": ["Blues Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
151	2019-12-22 18:40:27.827977	22	144	Dummy	2008-03-24 00:00:00	2	{"Year": 2008, "Catno": "828 522-1", "Genres": ["Electronic", "Rock"], "Styles": ["Trip Hop"], "Barcode": "042282852212", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}], "LabelCode": "LC 07192"}
152	2019-12-22 18:40:27.827977	42	145	Blood, Sweat And Tears	1969-01-01 00:00:00	2	{"Year": 1969, "Catno": "CS 9720", "Genres": ["Jazz", "Rock", "Funk / Soul"], "Styles": ["Blues Rock", "Jazz-Funk", "Jazz-Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
153	2019-12-22 18:40:27.827977	51	147	Harvest	1972-02-01 00:00:00	2	{"Year": 1972, "Catno": "MS 2032", "Genres": ["Rock"], "Styles": ["Folk Rock", "Country Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
154	2019-12-22 18:40:27.827977	5	148	The College Dropout	2004-02-10 00:00:00	4	{"Year": 2004, "Catno": "B0002030-01", "Genres": ["Hip Hop"], "Styles": ["Pop Rap", "Conscious", "Contemporary R&B"], "Barcode": "602498617410", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
155	2019-12-22 18:40:27.827977	5	148	My Beautiful Dark Twisted Fantasy	2010-11-01 00:00:00	6	{"Year": 2010, "Catno": "B0014695-01", "Genres": ["Hip Hop"], "Barcode": "6 02527 59493 4", "Country": "US", "Formats": [{"qty": "3", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
156	2019-12-22 18:40:27.827977	13	149	Point Of Know Return	1977-01-01 00:00:00	2	{"Year": 1977, "Catno": "JZ 34929", "Genres": ["Rock"], "Styles": ["Prog Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
157	2019-12-22 18:40:27.827977	42	150	Coming Home	2015-06-23 00:00:00	2	{"Year": 2015, "Catno": "88875 08914 1", "Genres": ["Funk / Soul"], "Styles": ["Soul", "Funk", "Rhythm & Blues"], "Barcode": "888750891419", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
158	2019-12-22 18:40:27.827977	51	151	Dookie	2009-04-18 00:00:00	2	{"Year": 2009, "Catno": "468284-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Power Pop", "Punk"], "Barcode": "093624986959", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
159	2019-12-22 18:40:27.827977	75	157	Helplessness Blues	2011-05-03 00:00:00	4	{"Year": 2011, "Catno": "SP 888", "Genres": ["Rock", "Folk, World, & Country"], "Styles": ["Indie Rock", "Folk"], "Barcode": "0 98787 08881 6", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
160	2019-12-22 18:40:27.827977	75	157	Fleet Foxes	2008-06-03 00:00:00	5	{"Year": 2008, "Catno": "SP 777", "Genres": ["Rock"], "Styles": ["Folk Rock", "Indie Rock"], "Barcode": "098787077711", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "Vinyl", "descriptions": ["12\\"", "EP"]}]}
161	2019-12-22 18:40:27.827977	41	158	Hot Rocks 1964-1971	1971-01-01 00:00:00	4	{"Year": 1971, "Catno": "2PS 606/7", "Genres": ["Rock"], "Styles": ["Blues Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
162	2019-12-22 18:40:27.827977	59	158	Some Girls	1978-06-01 00:00:00	2	{"Year": 1978, "Catno": "COC 39108", "Genres": ["Rock"], "Styles": ["Blues Rock", "Rock & Roll", "Classic Rock", "Disco"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
163	2019-12-22 18:40:27.827977	59	158	Tattoo You	1981-09-01 00:00:00	2	{"Year": 1981, "Catno": "COC 16052", "Genres": ["Rock"], "Styles": ["Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
164	2019-12-22 18:40:27.827977	42	159	Cheap Thrills	1968-08-12 00:00:00	2	{"Year": 1968, "Catno": "KCS 9700", "Genres": ["Rock"], "Styles": ["Folk Rock", "Blues Rock", "Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
165	2019-12-22 18:40:27.827977	42	160	Business As Usual	1982-01-01 00:00:00	2	{"Year": 1982, "Catno": "FC 37978", "Genres": ["Rock"], "Styles": ["Pop Rock", "New Wave"], "Barcode": "074643797818", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
166	2019-12-22 18:40:27.827977	21	161	Double Fantasy	1980-11-17 00:00:00	2	{"Year": 1980, "Catno": "GHS 2001", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
167	2019-12-22 18:40:27.827977	46	162	Graceland	1986-09-01 00:00:00	2	{"Year": 1986, "Catno": "1-25447", "Genres": ["Jazz", "Rock", "Funk / Soul", "Pop", "Folk, World, & Country"], "Styles": ["Folk Rock", "Pop Rock", "African", "Afrobeat", "Zydeco", "Funk", "Rhythm & Blues"], "Barcode": "0 7599-25447-1", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
168	2019-12-22 18:40:27.827977	42	162	Still Crazy After All These Years	1975-10-01 00:00:00	2	{"Year": 1975, "Catno": "PC 33540", "Genres": ["Rock"], "Styles": ["Folk Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
169	2019-12-22 18:40:27.827977	31	163	mbv	2013-02-22 00:00:00	3	{"Year": 2013, "Catno": "mbv lp 01", "Genres": ["Rock"], "Styles": ["Shoegaze"], "Barcode": "6 34457601819", "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "CD", "descriptions": ["Album"]}, {"qty": "1", "name": "All Media", "descriptions": ["Limited Edition"]}]}
170	2019-12-22 18:40:27.827977	17	164	The Unforgettable Fire	1984-01-01 00:00:00	2	{"Year": 1984, "Catno": "90231-1", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Barcode": "075679023117", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
171	2019-12-22 18:40:27.827977	17	164	The Joshua Tree	1987-03-09 00:00:00	2	{"Year": 1987, "Catno": "208 219", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Pop Rock"], "Barcode": "4007192082193", "Country": "Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}], "LabelCode": "LC 0407"}
172	2019-12-22 18:40:27.827977	64	165	Blunderbuss	2012-04-26 00:00:00	2	{"Year": 2012, "Catno": "TMR-139", "Genres": ["Rock"], "Styles": ["Blues Rock"], "Barcode": "8 86919 59931 2", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
173	2019-12-22 18:40:27.827977	64	165	Lazaretto	2014-06-10 00:00:00	2	{"Year": 2014, "Catno": "TMR-271", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Blues Rock", "Country Rock"], "Barcode": "8 88430 63981 2", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Etched"]}]}
174	2019-12-22 18:40:27.827977	42	166	At Folsom Prison	1968-05-01 00:00:00	2	{"Year": 1968, "Catno": "CS 9639", "Genres": ["Folk, World, & Country"], "Styles": ["Country"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
175	2019-12-22 18:40:27.827977	42	166	Johnny Cash At San Quentin	1969-01-01 00:00:00	2	{"Year": 1969, "Catno": "CS 9827", "Genres": ["Rock", "Folk, World, & Country"], "Styles": ["Country Rock", "Country"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
176	2019-12-22 18:40:27.827977	25	167	Whatever People Say I Am, That's What I'm Not	2006-01-23 00:00:00	2	{"Year": 2006, "Catno": "WIGLP162", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "5034202016212", "Country": "UK & Europe", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC10192"}
177	2019-12-22 18:40:27.827977	25	167	AM	2013-09-09 00:00:00	2	{"Year": 2013, "Catno": "WIGLP317", "Genres": ["Rock"], "Styles": ["Indie Rock", "Alternative Rock"], "Barcode": "887828031719", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
178	2019-12-22 18:40:27.827977	52	171	1962-1966	1973-04-19 00:00:00	4	{"Year": 1973, "Catno": "PCSP 717", "Genres": ["Rock", "Pop"], "Styles": ["Beat", "Pop Rock", "Rock & Roll"], "Country": "UK", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Compilation"]}]}
179	2019-12-22 18:40:27.827977	52	171	The Beatles	1968-01-01 00:00:00	4	{"Year": 1968, "Catno": "SWBO 101", "Genres": ["Rock", "Pop"], "Styles": ["Psychedelic Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Numbered", "Repress", "Stereo"]}]}
180	2019-12-22 18:40:27.827977	6	171	Sgt. Pepper's Lonely Hearts Club Band	1968-01-01 00:00:00	2	{"Year": 1968, "Catno": "SMAS 2653", "Genres": ["Rock"], "Styles": ["Psychedelic Rock", "Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
181	2019-12-22 18:40:27.827977	6	171	Magical Mystery Tour	1967-11-27 00:00:00	2	{"Year": 1967, "Catno": "SMAL-2835", "Genres": ["Rock"], "Styles": ["Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
182	2019-12-22 18:40:27.827977	52	171	1967-1970	1973-01-01 00:00:00	4	{"Year": 1973, "Catno": "SKBO 3404", "Genres": ["Rock"], "Styles": ["Rock & Roll", "Pop Rock", "Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
183	2019-12-22 18:40:27.827977	52	171	Abbey Road	1969-09-26 00:00:00	2	{"Year": 1969, "Catno": "PCS 7088", "Genres": ["Rock"], "Styles": ["Psychedelic Rock", "Pop Rock"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
184	2019-12-22 18:40:27.827977	52	171	Let It Be	1970-05-18 00:00:00	2	{"Year": 1970, "Catno": "AR 34001", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
185	2019-12-22 18:40:27.827977	63	172	Cosmo's Factory	1970-07-01 00:00:00	2	{"Year": 1970, "Catno": "8402", "Genres": ["Rock", "Blues"], "Styles": ["Blues Rock", "Rock & Roll", "Southern Rock", "Classic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
186	2019-12-22 18:40:27.827977	20	173	Reflektor	2013-10-29 00:00:00	4	{"Year": 2013, "Catno": "MRG485A", "Genres": ["Rock"], "Styles": ["Indie Rock"], "Barcode": "602537521197", "Country": "USA & Canada", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
187	2019-12-22 18:40:27.827977	20	173	The Suburbs	2010-08-03 00:00:00	4	{"Year": 2010, "Catno": "MRG385", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Indie Rock"], "Barcode": "673855038513", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
188	2019-12-22 18:40:27.827977	20	173	Funeral	2009-12-15 00:00:00	2	{"Year": 2009, "Catno": "MRG255", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Indie Rock"], "Barcode": "6 73855 02551 3", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
189	2019-12-22 18:40:27.827977	56	174	...Like Clockwork	2013-05-31 00:00:00	4	{"Year": 2013, "Catno": "OLE-1040-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Stoner Rock"], "Barcode": "7 44861 10401 8", "Country": "UK, Europe & US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["12\\"", "45 RPM", "Album"]}]}
190	2019-12-22 18:40:27.827977	74	175	Axis: Bold As Love	2010-03-09 00:00:00	2	{"Year": 2010, "Catno": "88697 62396 1", "Genres": ["Rock"], "Styles": ["Blues Rock", "Hard Rock", "Psychedelic Rock", "Acid Rock"], "Barcode": "0886976239619", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
191	2019-12-22 18:40:27.827977	51	175	Are You Experienced?	1967-08-23 00:00:00	2	{"Year": 1967, "Catno": "RS 6261", "Genres": ["Rock"], "Styles": ["Blues Rock", "Psychedelic Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
192	2019-12-22 18:40:27.827977	42	177	Born To Run	1975-01-01 00:00:00	2	{"Year": 1975, "Catno": "PC 33795", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
193	2019-12-22 18:40:27.827977	42	177	Darkness On The Edge Of Town	1978-06-02 00:00:00	2	{"Year": 1978, "Catno": "JC 35318", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
194	2019-12-22 18:40:27.827977	42	177	The River	1980-01-01 00:00:00	4	{"Year": 1980, "Catno": "PC2 36854", "Genres": ["Rock"], "Styles": ["Folk Rock", "Pop Rock", "Classic Rock"], "Barcode": "074643685412", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
195	2019-12-22 18:40:27.827977	42	177	Born In The U.S.A.	1984-06-04 00:00:00	2	{"Year": 1984, "Catno": "QC 38653", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Barcode": "074643865319", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
196	2019-12-22 18:40:27.827977	14	178	Turn Blue	2014-05-09 00:00:00	3	{"Year": 2014, "Catno": "542300-1", "Genres": ["Rock", "Blues"], "Styles": ["Alternative Rock"], "Barcode": "075597955552", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "CD", "descriptions": ["Album", "Promo"]}]}
197	2019-12-22 18:40:27.827977	14	178	Brothers	2010-05-18 00:00:00	5	{"Year": 2010, "Catno": "520266-1", "Genres": ["Rock", "Blues", "Folk, World, & Country"], "Styles": ["Blues Rock", "Indie Rock"], "Barcode": "075597979381", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "CD", "descriptions": ["Album"]}]}
198	2019-12-22 18:40:27.827977	14	178	El Camino	2011-12-06 00:00:00	3	{"Year": 2011, "Catno": "529099-1", "Genres": ["Rock", "Blues"], "Styles": ["Blues Rock", "Alternative Rock", "Garage Rock"], "Barcode": "075597963335", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}, {"qty": "1", "name": "CD", "descriptions": ["Album"]}]}
199	2019-12-22 18:40:27.827977	71	179	Music Has The Right To Children	2013-10-21 00:00:00	4	{"Year": 2013, "Catno": "warplp55r", "Genres": ["Electronic"], "Styles": ["IDM", "Ambient"], "Barcode": "801061 80551 7", "Country": "UK", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Repress"]}]}
200	2019-12-22 18:40:27.827977	71	179	Tomorrow's Harvest	2013-06-10 00:00:00	4	{"Year": 2013, "Catno": "WARPLP257", "Genres": ["Electronic"], "Styles": ["Downtempo", "Ambient", "IDM", "Drone"], "Barcode": "801061025717", "Country": "UK", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}], "LabelCode": "LC02070"}
201	2019-12-22 18:40:27.827977	81	180	Hi Infidelity	1980-01-01 00:00:00	2	{"Year": 1980, "Catno": "FE 36844", "Genres": ["Rock"], "Styles": ["Pop Rock", "Classic Rock"], "Barcode": "074643684415", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
202	2019-12-22 18:40:27.827977	37	181	Lateralus	2005-08-26 00:00:00	4	{"Year": 2005, "Catno": "61422-31160-1 LP", "Genres": ["Rock"], "Styles": ["Prog Rock", "Heavy Metal"], "Barcode": "6 14223 11601 3", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Limited Edition", "Picture Disc", "Reissue"]}]}
203	2019-12-22 18:40:27.827977	20	182	In The Aeroplane Over The Sea	2009-11-03 00:00:00	2	{"Year": 2009, "Catno": "MRG136LP", "Genres": ["Rock"], "Styles": ["Indie Rock", "Lo-Fi"], "Barcode": "673855013619", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Repress"]}]}
204	2019-12-22 18:40:27.827977	23	183	Madvillainy	2004-03-19 00:00:00	24	{"Year": 2004, "Catno": "STH2065", "Genres": ["Hip Hop"], "Barcode": "659457206512", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
205	2019-12-22 18:40:27.827977	54	184	Sigh No More	2009-01-01 00:00:00	2	{"Year": 2009, "Catno": "GLS-0109-01", "Genres": ["Folk, World, & Country"], "Styles": ["Bluegrass", "Folk"], "Barcode": "8 92038 00224 4", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
206	2019-12-22 18:40:27.827977	34	185	Talking Heads: 77	1977-09-01 00:00:00	2	{"Year": 1977, "Catno": "SR 6036", "Genres": ["Rock"], "Styles": ["New Wave", "Art Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
207	2019-12-22 18:40:27.827977	34	185	Remain In Light	1980-10-01 00:00:00	2	{"Year": 1980, "Catno": "SRK 6095", "Genres": ["Electronic", "Rock", "Funk / Soul"], "Styles": ["New Wave", "Art Rock", "Funk"], "Barcode": "0 7599-26095-1", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
208	2019-12-22 18:40:27.827977	34	185	Stop Making Sense	1984-01-01 00:00:00	2	{"Year": 1984, "Catno": "1-25186", "Genres": ["Rock", "Funk / Soul"], "Styles": ["Funk", "Indie Rock", "New Wave"], "Barcode": "0075992518611", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
209	2019-12-22 18:40:27.827977	34	185	Little Creatures	1985-06-10 00:00:00	2	{"Year": 1985, "Catno": "9 25305-1", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Pop Rock"], "Barcode": "075992530514", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
210	2019-12-22 18:40:27.827977	34	185	Speaking In Tongues	1983-06-01 00:00:00	2	{"Year": 1983, "Catno": "1-23883", "Genres": ["Rock", "Funk / Soul"], "Styles": ["New Wave", "Pop Rock", "Funk"], "Barcode": "075992388313", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
211	2019-12-22 18:40:27.827977	6	186	Morning Phase	2014-02-25 00:00:00	2	{"Year": 2014, "Catno": "B001983901", "Genres": ["Rock", "Pop", "Folk, World, & Country"], "Styles": ["Folk", "Alternative Rock"], "Barcode": "602537649747", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
212	2019-12-22 18:40:27.827977	80	187	Hatful Of Hollow	1984-11-12 00:00:00	2	{"Year": 1984, "Catno": "ROUGH 76", "Genres": ["Rock"], "Styles": ["Alternative Rock", "Indie Rock"], "Barcode": "none", "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}], "LabelCode": "LC 5661"}
213	2019-12-22 18:40:27.827977	76	189	To Pimp A Butterfly	2015-10-23 00:00:00	4	{"Year": 2015, "Catno": "B0023464-01", "Genres": ["Hip Hop", "Funk / Soul"], "Styles": ["Pop Rap", "Jazzy Hip-Hop"], "Barcode": "602547311009", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
214	2019-12-22 18:40:27.827977	76	189	Good Kid, M.A.A.d City	2012-10-22 00:00:00	4	{"Year": 2012, "Catno": "B0017695-01", "Genres": ["Hip Hop"], "Styles": ["Conscious"], "Barcode": "602537192267", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Deluxe Edition"]}]}
215	2019-12-22 18:40:27.827977	77	190	Heartbeat City	1984-03-13 00:00:00	2	{"Year": 1984, "Catno": "60296-1", "Genres": ["Rock"], "Styles": ["Pop Rock"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
216	2019-12-22 18:40:27.827977	77	190	The Cars	1978-06-06 00:00:00	2	{"Year": 1978, "Catno": "6E-135", "Genres": ["Rock"], "Styles": ["New Wave", "Pop Rock", "Power Pop"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
217	2019-12-22 18:40:27.827977	33	191	Definitely Maybe	2014-05-19 00:00:00	4	{"Year": 2014, "Catno": "RKIDLP70", "Genres": ["Rock"], "Styles": ["Brit Pop", "Alternative Rock"], "Barcode": "5051961070019", "Country": "UK & Europe", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
218	2019-12-22 18:40:27.827977	33	191	(What's The Story) Morning Glory?	2014-09-26 00:00:00	4	{"Year": 2014, "Catno": "RKIDLP73", "Genres": ["Rock"], "Styles": ["Brit Pop"], "Barcode": "5051961073010", "Country": "UK, Europe & US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
219	2019-12-22 18:40:27.827977	6	192	Endless Summer	1974-06-24 00:00:00	4	{"Year": 1974, "Catno": "SVBB-11307", "Genres": ["Rock"], "Styles": ["Surf", "Pop Rock"], "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Compilation"]}]}
220	2019-12-22 18:40:27.827977	49	193	Deja Entendu	2015-05-05 00:00:00	4	{"Year": 2015, "Catno": "none", "Genres": ["Rock"], "Styles": ["Punk", "Emo"], "Barcode": "646920318216", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue"]}]}
221	2019-12-22 18:40:27.827977	9	196	The Chronic	2001-05-01 00:00:00	4	{"Year": 2001, "Catno": "DRR 63000-1", "Genres": ["Hip Hop"], "Styles": ["Gangsta", "G-Funk"], "Barcode": "728706300018", "Country": "US", "Formats": [{"qty": "2", "name": "Vinyl", "descriptions": ["LP", "Album", "Reissue", "Remastered"]}]}
222	2019-12-22 18:40:27.827977	46	197	Dire Straits	1978-01-01 00:00:00	2	{"Year": 1978, "Catno": "BSK 3266", "Genres": ["Rock"], "Styles": ["AOR", "Rock & Roll"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
223	2019-12-22 18:40:27.827977	19	197	Love Over Gold	1982-01-01 00:00:00	2	{"Year": 1982, "Catno": "6359 109", "Genres": ["Rock"], "Styles": ["Classic Rock"], "Country": "UK", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
224	2019-12-22 18:40:27.827977	46	197	Brothers In Arms	1985-01-01 00:00:00	2	{"Year": 1985, "Catno": "1-25264", "Genres": ["Rock"], "Styles": ["Classic Rock"], "Barcode": "075992526418", "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album"]}]}
225	2019-12-22 18:40:27.827977	18	198	The Graduate (Original Sound Track Recording)	1968-01-01 00:00:00	2	{"Year": 1968, "Catno": "OS 3180", "Genres": ["Jazz", "Rock", "Stage & Screen"], "Styles": ["Folk Rock", "Acoustic", "Soundtrack"], "Country": "US", "Formats": [{"qty": "1", "name": "Vinyl", "descriptions": ["LP", "Album", "Stereo"]}]}
\.


--
-- Data for Name: albums_countries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.albums_countries (album_id, country_code) FROM stdin;
1	US
2	US
3	US
4	US
5	US
6	US
7	US
8	US
9	US
10	US
11	US
12	US
13	US
14	US
15	US
16	US
17	US
18	US
19	US
20	US
21	US
22	US
23	US
24	US
25	US
26	US
27	US
28	US
29	US
30	US
31	US
32	US
33	US
34	US
35	US
36	US
37	US
38	US
39	US
40	US
41	US
42	US
43	US
44	US
45	US
46	US
47	US
48	US
49	US
50	US
51	US
52	US
53	US
54	US
55	US
56	US
57	US
58	US
59	US
60	US
61	US
62	US
129	US
63	US
64	US
65	US
66	US
67	US
68	US
69	US
70	US
71	US
72	US
73	US
74	US
75	US
76	US
77	US
78	US
79	US
80	US
81	US
82	US
83	US
84	US
85	US
86	US
87	US
88	US
89	US
90	US
91	US
92	US
93	US
94	US
95	US
96	US
97	US
98	US
99	US
100	US
101	US
102	US
103	US
104	US
105	US
106	US
107	US
108	US
109	US
110	US
111	US
112	US
113	US
114	US
115	US
116	US
117	US
118	US
119	US
120	US
121	US
122	US
123	US
124	US
125	US
126	US
127	US
128	US
130	US
131	US
132	US
133	US
134	US
135	US
136	US
137	US
138	US
139	US
140	US
141	US
142	US
143	US
144	US
145	US
146	US
147	US
148	US
149	US
150	US
151	US
152	US
153	US
154	US
155	US
156	US
157	US
158	US
159	US
160	US
161	US
162	US
163	US
164	US
165	US
166	US
167	US
168	US
169	US
170	US
171	US
172	US
173	US
174	US
175	US
176	US
177	US
178	US
179	US
180	US
181	US
182	US
183	US
184	US
185	US
186	US
187	US
188	US
189	US
190	US
191	US
192	US
193	US
194	US
195	US
196	US
197	US
198	US
199	US
200	US
201	US
202	US
203	US
204	US
205	US
206	US
207	US
208	US
209	US
210	US
211	US
212	US
213	US
214	US
215	US
216	US
217	US
218	US
219	US
220	US
221	US
222	US
223	US
224	US
225	US
1	RU
2	RU
3	RU
4	RU
8	RU
9	RU
10	RU
11	RU
12	RU
13	RU
14	RU
15	RU
16	RU
17	RU
18	RU
19	RU
20	RU
21	RU
22	RU
23	RU
24	RU
25	RU
26	RU
27	RU
28	RU
29	RU
30	RU
31	RU
32	RU
34	RU
35	RU
36	RU
37	RU
38	RU
39	RU
40	RU
42	RU
43	RU
44	RU
45	RU
46	RU
47	RU
48	RU
49	RU
50	RU
51	RU
52	RU
53	RU
54	RU
55	RU
56	RU
57	RU
58	RU
59	RU
60	RU
61	RU
62	RU
129	RU
63	RU
64	RU
65	RU
66	RU
67	RU
68	RU
69	RU
70	RU
71	RU
72	RU
73	RU
74	RU
75	RU
76	RU
77	RU
78	RU
79	RU
80	RU
81	RU
82	RU
83	RU
84	RU
85	RU
86	RU
89	RU
90	RU
91	RU
92	RU
93	RU
94	RU
95	RU
96	RU
98	RU
99	RU
100	RU
101	RU
102	RU
103	RU
104	RU
105	RU
106	RU
107	RU
108	RU
109	RU
110	RU
112	RU
113	RU
114	RU
115	RU
116	RU
117	RU
118	RU
119	RU
120	RU
121	RU
122	RU
123	RU
124	RU
125	RU
126	RU
127	RU
128	RU
130	RU
131	RU
132	RU
133	RU
134	RU
135	RU
136	RU
137	RU
138	RU
139	RU
140	RU
141	RU
142	RU
143	RU
144	RU
145	RU
146	RU
147	RU
148	RU
149	RU
150	RU
151	RU
152	RU
153	RU
154	RU
155	RU
156	RU
157	RU
158	RU
159	RU
160	RU
161	RU
162	RU
163	RU
164	RU
165	RU
166	RU
167	RU
168	RU
169	RU
170	RU
171	RU
172	RU
173	RU
174	RU
175	RU
176	RU
177	RU
178	RU
179	RU
180	RU
181	RU
182	RU
183	RU
184	RU
185	RU
186	RU
187	RU
188	RU
189	RU
190	RU
191	RU
192	RU
193	RU
194	RU
195	RU
196	RU
197	RU
198	RU
199	RU
200	RU
202	RU
203	RU
204	RU
205	RU
206	RU
207	RU
208	RU
209	RU
210	RU
211	RU
212	RU
213	RU
214	RU
215	RU
216	RU
217	RU
218	RU
219	RU
220	RU
221	RU
222	RU
223	RU
224	RU
225	RU
4	BY
5	BY
6	BY
7	BY
8	BY
13	BY
14	BY
16	BY
18	BY
19	BY
22	BY
25	BY
32	BY
33	BY
41	BY
42	BY
43	BY
44	BY
45	BY
48	BY
49	BY
50	BY
51	BY
59	BY
60	BY
61	BY
62	BY
65	BY
66	BY
67	BY
68	BY
82	BY
87	BY
88	BY
91	BY
94	BY
96	BY
97	BY
105	BY
109	BY
110	BY
111	BY
114	BY
116	BY
117	BY
118	BY
119	BY
121	BY
122	BY
123	BY
126	BY
128	BY
130	BY
145	BY
146	BY
153	BY
154	BY
155	BY
156	BY
158	BY
159	BY
160	BY
161	BY
162	BY
163	BY
166	BY
169	BY
170	BY
171	BY
176	BY
177	BY
185	BY
191	BY
199	BY
200	BY
201	BY
202	BY
204	BY
215	BY
216	BY
217	BY
218	BY
220	BY
221	BY
223	BY
\.


--
-- Data for Name: artists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.artists (id, created_at, name, specs) FROM stdin;
1	2019-12-22 17:45:46.653988	Gorillaz & Mos Def	{}
2	2019-12-22 17:45:46.672752	Dusty Springfield	{}
3	2019-12-22 17:45:46.679606	Nick Cave & The Bad Seeds	{}
4	2019-12-22 17:45:46.68563	Wham!	{}
5	2019-12-22 17:45:46.69102	Snoop Dogg	{}
6	2019-12-22 17:45:46.699413	Gorillaz & Snoop Dogg	{}
7	2019-12-22 17:45:46.705061	Michael Jackson	{}
8	2019-12-22 17:45:46.710538	Strokes, The	{}
9	2019-12-22 17:45:46.717709	New Order	{}
10	2019-12-22 17:45:46.722961	Stevie Wonder	{}
11	2019-12-22 17:45:46.727898	Blondie	{}
12	2019-12-22 17:45:46.73276	Steve Miller Band	{}
13	2019-12-22 17:45:46.738956	Tim Roth & Amanda Plummer	{}
14	2019-12-22 17:45:46.74507	Blue Swede	{}
15	2019-12-22 17:45:46.751808	Daft Punk	{}
16	2019-12-22 17:45:46.759265	Prince And The Revolution	{}
17	2019-12-22 17:45:46.76536	Radiohead	{}
18	2019-12-22 17:45:46.772976	Rupert Holmes	{}
19	2019-12-22 17:45:46.781549	Amy Winehouse	{}
20	2019-12-22 17:45:46.787179	Louis St. Louis	{}
21	2019-12-22 17:45:46.796206	Marvin Gaye & Tammi Terrell	{}
22	2019-12-22 17:45:46.803104	Bee Gees	{}
23	2019-12-22 17:45:46.812127	Ralph MacDonald	{}
24	2019-12-22 17:45:46.820918	Stardust	{}
25	2019-12-22 17:45:46.828236	George Harrison	{}
26	2019-12-22 17:45:46.837468	Knack (3), The	{}
27	2019-12-22 17:45:46.844612	Bob Seger And The Silver Bullet Band	{}
28	2019-12-22 17:45:46.84906	Cure, The	{}
29	2019-12-22 17:45:46.8518	KC & The Sunshine Band	{}
30	2019-12-22 17:45:46.855274	Huey Lewis & The News	{}
31	2019-12-22 17:45:46.85823	XX, The	{}
32	2019-12-22 17:45:46.860528	Pearl Jam	{}
33	2019-12-22 17:45:46.863268	Peter Greene & Duane Whitaker	{}
34	2019-12-22 17:45:46.866011	Fleetwood Mac	{}
35	2019-12-22 17:45:46.86832	Led Zeppelin	{}
36	2019-12-22 17:45:46.870439	Death Grips	{}
37	2019-12-22 17:45:46.872551	Pixies	{}
38	2019-12-22 17:45:46.875789	Animal Collective	{}
39	2019-12-22 17:45:46.878832	Peter Gabriel	{}
40	2019-12-22 17:45:46.882407	Dick Dale & His Del-Tones	{}
41	2019-12-22 17:45:46.885326	Al Green	{}
42	2019-12-22 17:45:46.887938	Sufjan Stevens	{}
43	2019-12-22 17:45:46.890451	Journey	{}
44	2019-12-22 17:45:46.893371	Foreigner	{}
45	2019-12-22 17:45:46.897015	Ricky Nelson (2)	{}
46	2019-12-22 17:45:46.901385	Maria De Medeiros & Bruce Willis	{}
47	2019-12-22 17:45:46.905401	Jerome Patrick Hoban	{}
48	2019-12-22 17:45:46.909043	Elton John	{}
49	2019-12-22 17:45:46.912356	Guns N' Roses	{}
50	2019-12-22 17:45:46.915864	David Bowie	{}
51	2019-12-22 17:45:46.9216	John Williams (4), London Symphony Orchestra, The	{}
52	2019-12-22 17:45:46.925485	Nas	{}
53	2019-12-22 17:45:46.92907	Styx	{}
54	2019-12-22 17:45:46.933238	Willie Nelson	{}
55	2019-12-22 17:45:46.938085	John Travolta	{}
56	2019-12-22 17:45:46.943361	Elvin Bishop	{}
57	2019-12-22 17:45:46.947297	MFSB	{}
58	2019-12-22 17:45:46.952152	Various	{}
59	2019-12-22 17:45:46.956883	King Crimson	{}
60	2019-12-22 17:45:46.965087	AC/DC	{}
61	2019-12-22 17:45:46.967928	Frankie Valli	{}
62	2019-12-22 17:45:46.971267	The Tornadoes	{}
63	2019-12-22 17:45:46.976042	The Revels	{}
64	2019-12-22 17:45:46.979878	John Travolta & Samuel L. Jackson	{}
65	2019-12-22 17:45:46.982497	Doors, The	{}
66	2019-12-22 17:45:46.985295	Tom Petty And The Heartbreakers	{}
67	2019-12-22 17:45:46.991295	Beastie Boys	{}
68	2019-12-22 17:45:46.995068	Gorillaz & Yukimi Nagano	{}
69	2019-12-22 17:45:46.998233	Samuel L. Jackson & John Travolta	{}
70	2019-12-22 17:45:47.000719	Chuck Berry	{}
71	2019-12-22 17:45:47.008149	Stevie Nicks	{}
72	2019-12-22 17:45:47.012339	Jackson Browne	{}
73	2019-12-22 17:45:47.015585	Louis St. Louis & Cindy Bullens	{}
74	2019-12-22 17:45:47.01828	Olivia Newton-John	{}
75	2019-12-22 17:45:47.021868	Unknown Artist	{}
76	2019-12-22 17:45:47.036311	Sha-Na-Na	{}
77	2019-12-22 17:45:47.040828	Norman Greenbaum	{}
78	2019-12-22 17:45:47.045795	10cc	{}
79	2019-12-22 17:45:47.049291	Bob Dylan	{}
80	2019-12-22 17:45:47.053396	Madonna	{}
81	2019-12-22 17:45:47.057872	Blues Brothers, The	{}
82	2019-12-22 17:45:47.061152	David Shire	{}
83	2019-12-22 17:45:47.064785	Police, The	{}
84	2019-12-22 17:45:47.06783	Santana	{}
85	2019-12-22 17:45:47.084273	Simply Red	{}
86	2019-12-22 17:45:47.088773	Peter Frampton	{}
87	2019-12-22 17:45:47.092653	Aerosmith	{}
88	2019-12-22 17:45:47.098902	War On Drugs, The	{}
89	2019-12-22 17:45:47.103106	Boston	{}
90	2019-12-22 17:45:47.108232	Godspeed You Black Emperor!	{}
91	2019-12-22 17:45:47.112654	Samuel L. Jackson	{}
92	2019-12-22 17:45:47.116899	Aphex Twin	{}
93	2019-12-22 17:45:47.11967	Gorillaz	{}
94	2019-12-22 17:45:47.122247	Queen	{}
95	2019-12-22 17:45:47.125293	Tracy Chapman	{}
96	2019-12-22 17:45:47.127796	Meat Loaf	{}
97	2019-12-22 17:45:47.131442	Billy Joel	{}
98	2019-12-22 17:45:47.1345	Crosby, Stills, Nash & Young	{}
99	2019-12-22 17:45:47.137102	Bon Iver	{}
100	2019-12-22 17:45:47.140464	Maria McKee	{}
101	2019-12-22 17:45:47.143103	Adele (3)	{}
102	2019-12-22 17:45:47.146458	Angelo Badalamenti	{}
103	2019-12-22 17:45:47.150352	Frankie Avalon	{}
104	2019-12-22 17:45:47.153047	Cindy Bullens	{}
105	2019-12-22 17:45:47.157826	Gorillaz & Bashy & Kano (4)	{}
106	2019-12-22 17:45:47.16238	Yvonne Elliman	{}
107	2019-12-22 17:45:47.166678	Supertramp	{}
108	2019-12-22 17:45:47.170052	Nirvana	{}
109	2019-12-22 17:45:47.173451	Sade	{}
110	2019-12-22 17:45:47.177551	Run The Jewels	{}
111	2019-12-22 17:45:47.182432	Tame Impala	{}
112	2019-12-22 17:45:47.186649	Herbie Hancock	{}
113	2019-12-22 17:45:47.191613	Alan Parsons Project, The	{}
114	2019-12-22 17:45:47.195819	The Jackson 5	{}
115	2019-12-22 17:45:47.19953	Wu-Tang Clan	{}
116	2019-12-22 17:45:47.214947	Kamasi Washington	{}
117	2019-12-22 17:45:47.218686	Smashing Pumpkins, The	{}
118	2019-12-22 17:45:47.222994	Tyler Bates	{}
119	2019-12-22 17:45:47.227888	Five Stairsteps	{}
120	2019-12-22 17:45:47.231888	Red Hot Chili Peppers	{}
121	2019-12-22 17:45:47.235192	Eddie Vedder	{}
122	2019-12-22 17:45:47.24173	Gorillaz & Lou Reed	{}
123	2019-12-22 17:45:47.245481	Neil Young & Crazy Horse	{}
124	2019-12-22 17:45:47.248805	National, The	{}
125	2019-12-22 17:45:47.252446	Chicago (2)	{}
126	2019-12-22 17:45:47.256818	America (2)	{}
127	2019-12-22 17:45:47.259476	Pink Floyd	{}
128	2019-12-22 17:45:47.262411	Simon & Garfunkel	{}
129	2019-12-22 17:45:47.265237	Miles Davis	{}
130	2019-12-22 17:45:47.268788	Allman Brothers Band, The	{}
131	2019-12-22 17:45:47.272503	Wilco	{}
132	2019-12-22 17:45:47.276128	White Stripes, The	{}
133	2019-12-22 17:45:47.279418	The Centurions (2)	{}
134	2019-12-22 17:45:47.281856	Tavares	{}
135	2019-12-22 17:45:47.284233	Carole King	{}
136	2019-12-22 17:45:47.287654	Wings (2)	{}
137	2019-12-22 17:45:47.291195	Alice In Chains	{}
138	2019-12-22 17:45:47.29481	Van Halen	{}
139	2019-12-22 17:45:47.299003	Steely Dan	{}
140	2019-12-22 17:45:47.302773	Band Of Horses	{}
141	2019-12-22 17:45:47.306833	Cat Stevens	{}
142	2019-12-22 17:45:47.310483	Eagles	{}
143	2019-12-22 17:45:47.3145	Janis Joplin	{}
144	2019-12-22 17:45:47.318445	Portishead	{}
145	2019-12-22 17:45:47.322039	Blood, Sweat And Tears	{}
146	2019-12-22 17:45:47.327047	Stockard Channing	{}
147	2019-12-22 17:45:47.330217	Neil Young	{}
148	2019-12-22 17:45:47.33349	Kanye West	{}
149	2019-12-22 17:45:47.337666	Kansas (2)	{}
150	2019-12-22 17:45:47.342379	Leon Bridges	{}
151	2019-12-22 17:45:47.34643	Green Day	{}
152	2019-12-22 17:45:47.351149	John Travolta & Olivia Newton-John	{}
153	2019-12-22 17:45:47.353707	Gorillaz & Bobby Womack	{}
154	2019-12-22 17:45:47.357584	Urge Overkill	{}
155	2019-12-22 17:45:47.359946	The Statler Brothers	{}
156	2019-12-22 17:45:47.363109	Raspberries	{}
157	2019-12-22 17:45:47.366285	Fleet Foxes	{}
158	2019-12-22 17:45:47.369827	Rolling Stones, The	{}
159	2019-12-22 17:45:47.373968	Big Brother & The Holding Company	{}
160	2019-12-22 17:45:47.376929	Men At Work	{}
161	2019-12-22 17:45:47.380139	John Lennon & Yoko Ono	{}
162	2019-12-22 17:45:47.383716	Paul Simon	{}
163	2019-12-22 17:45:47.387006	My Bloody Valentine	{}
164	2019-12-22 17:45:47.390464	U2	{}
165	2019-12-22 17:45:47.392943	Jack White (2)	{}
166	2019-12-22 17:45:47.395696	Johnny Cash	{}
167	2019-12-22 17:45:47.399685	Arctic Monkeys	{}
168	2019-12-22 17:45:47.40286	Gorillaz & Mark E. Smith	{}
169	2019-12-22 17:45:47.407583	The Runaways	{}
170	2019-12-22 17:45:47.411583	Dave Grusin	{}
171	2019-12-22 17:45:47.414967	Beatles, The	{}
172	2019-12-22 17:45:47.419142	Creedence Clearwater Revival	{}
173	2019-12-22 17:45:47.423599	Arcade Fire	{}
174	2019-12-22 17:45:47.4289	Queens Of The Stone Age	{}
175	2019-12-22 17:45:47.432436	Jimi Hendrix Experience, The	{}
176	2019-12-22 17:45:47.436258	Tha Dogg Pound	{}
177	2019-12-22 17:45:47.441537	Bruce Springsteen	{}
178	2019-12-22 17:45:47.445561	Black Keys, The	{}
179	2019-12-22 17:45:47.449019	Boards Of Canada	{}
180	2019-12-22 17:45:47.453559	REO Speedwagon	{}
181	2019-12-22 17:45:47.457606	Tool (2)	{}
182	2019-12-22 17:45:47.462912	Neutral Milk Hotel	{}
183	2019-12-22 17:45:47.466502	MF Doom & Madlib - Madvillain	{}
184	2019-12-22 17:45:47.470185	Mumford & Sons	{}
185	2019-12-22 17:45:47.473879	Talking Heads	{}
186	2019-12-22 17:45:47.477273	Beck	{}
187	2019-12-22 17:45:47.480724	Smiths, The	{}
188	2019-12-22 17:45:47.483584	Kool & The Gang	{}
189	2019-12-22 17:45:47.48622	Kendrick Lamar	{}
190	2019-12-22 17:45:47.488587	Cars, The	{}
191	2019-12-22 17:45:47.491913	Oasis (2)	{}
192	2019-12-22 17:45:47.495471	Beach Boys, The	{}
193	2019-12-22 17:45:47.498313	Brand New	{}
194	2019-12-22 17:45:47.500791	The Lively Ones	{}
195	2019-12-22 17:45:47.503397	Walter Murphy	{}
196	2019-12-22 17:45:47.506683	Dr. Dre	{}
197	2019-12-22 17:45:47.508966	Dire Straits	{}
198	2019-12-22 17:45:47.511399	Simon & Garfunkel, Dave Grusin	{}
199	2019-12-22 17:45:47.513998	Gorillaz & De La Soul & Gruff Rhys	{}
200	2019-12-22 17:45:47.516286	Redbone	{}
201	2019-12-22 17:45:48.54637	The Trammps	{}
\.


--
-- Data for Name: countries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.countries (id, name) FROM stdin;
AF	Afghanistan
AL	Albania
DZ	Algeria
AD	Andorra
AO	Angola
AG	Antigua and Barbuda
AR	Argentina
AM	Armenia
AU	Australia
AT	Austria
AZ	Azerbaijan
BS	Bahamas
BH	Bahrain
BD	Bangladesh
BB	Barbados
BY	Belarus
BE	Belgium
BZ	Belize
BJ	Benin
BT	Bhutan
BO	Bolivia (Plurinational State of)
BA	Bosnia and Herzegovina
BW	Botswana
BR	Brazil
BN	Brunei Darussalam
BG	Bulgaria
BF	Burkina Faso
BI	Burundi
CV	Cabo Verde
KH	Cambodia
CM	Cameroon
CA	Canada
CF	Central African Republic
TD	Chad
CL	Chile
CN	China
CO	Colombia
KM	Comoros
CG	Congo
CD	Congo, Democratic Republic of the
CR	Costa Rica
CI	Côte dIvoire
HR	Croatia
CU	Cuba
CY	Cyprus
CZ	Czechia
DK	Denmark
DJ	Djibouti
DM	Dominica
DO	Dominican Republic
EC	Ecuador
EG	Egypt
SV	El Salvador
GQ	Equatorial Guinea
ER	Eritrea
EE	Estonia
SZ	Eswatini
ET	Ethiopia
FJ	Fiji
FI	Finland
FR	France
GA	Gabon
GM	Gambia
GE	Georgia
DE	Germany
GH	Ghana
GR	Greece
GD	Grenada
GT	Guatemala
GN	Guinea
GW	Guinea-Bissau
GY	Guyana
HT	Haiti
HN	Honduras
HU	Hungary
IS	Iceland
IN	India
ID	Indonesia
IR	Iran (Islamic Republic of)
IQ	Iraq
IE	Ireland
IL	Israel
IT	Italy
JM	Jamaica
JP	Japan
JO	Jordan
KZ	Kazakhstan
KE	Kenya
KI	Kiribati
KP	Korea (Democratic Peoples Republic of)
KR	Korea, Republic of
KW	Kuwait
KG	Kyrgyzstan
LA	Lao Peoples Democratic Republic
LV	Latvia
LB	Lebanon
LS	Lesotho
LR	Liberia
LY	Libya
LI	Liechtenstein
LT	Lithuania
LU	Luxembourg
MG	Madagascar
MW	Malawi
MY	Malaysia
MV	Maldives
ML	Mali
MT	Malta
MH	Marshall Islands
MR	Mauritania
MU	Mauritius
MX	Mexico
FM	Micronesia (Federated States of)
MD	Moldova, Republic of
MC	Monaco
MN	Mongolia
ME	Montenegro
MA	Morocco
MZ	Mozambique
MM	Myanmar
NA	Namibia
NR	Nauru
NP	Nepal
NL	Netherlands
NZ	New Zealand
NI	Nicaragua
NE	Niger
NG	Nigeria
MK	North Macedonia
NO	Norway
OM	Oman
PK	Pakistan
PW	Palau
PA	Panama
PG	Papua New Guinea
PY	Paraguay
PE	Peru
PH	Philippines
PL	Poland
PT	Portugal
QA	Qatar
RO	Romania
RU	Russian Federation
RW	Rwanda
KN	Saint Kitts and Nevis
LC	Saint Lucia
VC	Saint Vincent and the Grenadines
WS	Samoa
SM	San Marino
ST	Sao Tome and Principe
SA	Saudi Arabia
SN	Senegal
RS	Serbia
SC	Seychelles
SL	Sierra Leone
SG	Singapore
SK	Slovakia
SI	Slovenia
SB	Solomon Islands
SO	Somalia
ZA	South Africa
SS	South Sudan
ES	Spain
LK	Sri Lanka
SD	Sudan
SR	Suriname
SE	Sweden
CH	Switzerland
SY	Syrian Arab Republic
TJ	Tajikistan
TZ	Tanzania, United Republic of
TH	Thailand
TL	Timor-Leste
TG	Togo
TO	Tonga
TT	Trinidad and Tobago
TN	Tunisia
TR	Turkey
TM	Turkmenistan
TV	Tuvalu
UG	Uganda
UA	Ukraine
AE	United Arab Emirates
GB	United Kingdom of Great Britain and Northern Ireland
US	United States of America
UY	Uruguay
UZ	Uzbekistan
VU	Vanuatu
VE	Venezuela (Bolivarian Republic of)
VN	Viet Nam
YE	Yemen
ZM	Zambia
ZW	Zimbabwe
\.


--
-- Data for Name: labels; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.labels (id, created_at, name, founded_at, specs) FROM stdin;
4	2019-12-22 17:35:40.391405	A&M Records	\N	{"Urls": ["http://www.cvinyl.com/labelguides/a&m.php", "http://www.interscope.com/", "http://aandmrecords.co.uk/", "http://www.onamrecords.com/", "http://www.amcorner.com/", "http://www.bsnpubs.com/aandm/", "http://en.wikipedia.org/wiki/A&M_Records", "http://www.discogs.com/forum/thread/397995"], "ContactInfo": "[DEFUNCT]\\r\\nA&M Records\\r\\n2220 Colorado Avenue\\r\\nSanta Monica, CA 90404\\r\\nU.S.A.\\r\\n"}
5	2019-12-22 17:35:40.41999	Roc-A-Fella Records	\N	{"Urls": ["http://www.islanddefjam.com/default.aspx?labelID=75", "http://myspace.com/rocafellarecords", "http://twitter.com/Roc_A_Fella", "http://en.wikipedia.org/wiki/Roc-A-Fella_Records"], "ContactInfo": "sitesupport@rocafella.com"}
6	2019-12-22 17:35:40.71367	Capitol Records	\N	{"Urls": ["http://www.capitolrecords.com", "http://www.capitolrecords.co.uk", "http://www.cvinyl.com/labelguides/capitol.php", "http://www.facebook.com/capitolrecords", "http://www.facebook.com/CapitolRecordsUK", "http://plus.google.com/+capitolrecordsUS", "http://plus.google.com/106842824297178067659", "http://instagram.com/capitolrecords", "http://www.pinterest.com/capitolrecords", "http://soundcloud.com/capitol-records", "http://soundcloud.com/capitol-recordsuk", "http://capitolrecords.tumblr.com", "http://twitter.com/CapitolRecords", "http://twitter.com/Capital_Records", "http://twitter.com/CapitolUK", "http://en.wikipedia.org/wiki/Capitol_Records", "http://www.youtube.com/user/capitolrecordsUS", "http://www.youtube.com/user/CapitolRecordsUK", "http://eighthavenue.com/capitol.htm", "http://www.vinylbeat.com/cgi-bin/labelfocus.cgi?label=CAPITOL&label_section=A,B,C", "http://www.friktech.com/btls/capitol/capitollabels.pdf", "http://www.imdb.com/company/co0118562/", "http://imgur.com/a/krnN3", "http://imgur.com/a/dRJz9", "https://www.bookogs.com/credit/141332-capitol-records"], "ContactInfo": "1750 North Vine Street\\r\\nHollywood, CA  90028\\r\\nUSA\\r\\n\\r\\n150 5th Avenue\\r\\nNew York, NY 10011\\r\\nUSA\\r\\n\\r\\nCapitol Records\\r\\n3322 West End Avenue\\r\\nNashville, TN 37203\\r\\n\\r\\nE-mail: ContactUs@CapitolRecords.com\\r\\nPhone: (323) 462-6252\\r\\n"}
7	2019-12-22 17:35:40.719534	Virgin	\N	{"Urls": ["http://www.virginrecords.com"]}
8	2019-12-22 17:35:40.723059	Bad Seed Ltd.	\N	{}
9	2019-12-22 17:35:40.729402	Death Row Records (2)	\N	{"ContactInfo": "Death Row Records\\r\\nATTN: A&R Dept.\\r\\nP.O. Box 3037\\r\\nBeverly Hills, CA 90212 - USA\\r\\n"}
10	2019-12-22 17:35:40.734716	Roulé	\N	{}
11	2019-12-22 17:35:40.740856	Backstreet Records	\N	{"ContactInfo": "90 Universal City Plaza\\r\\nUniversal City, California\\r\\n"}
12	2019-12-22 17:35:40.763089	Secretly Canadian	\N	{"Urls": ["http://www.secretlycanadian.com", "http://www.epitonic.com/labels/secretly-canadian-records", "http://www.facebook.com/SecretlyCanadian", "http://plus.google.com/+secretlycanadianinc", "http://instagram.com/SecretlyCanadian", "http://myspace.com/secretlycanadianrecords", "http://soundcloud.com/secretlycanadian", "http://twitter.com/secretlycndian", "http://vimeo.com/user2801297", "http://vimeo.com/channels/secretlyjag", "http://en.wikipedia.org/wiki/Secretly_Canadian", "http://www.youtube.com/user/secretlycanadianinc", "http://www.youtube.com/user/SecretlyJag"], "ContactInfo": "Secretly Canadian\\r\\n1499 West 2nd\\r\\nBloomington, IN 47403 \\r\\nUSA\\r\\n[url=mailto:info@secretlycanadian.com]info@secretlycanadian.com[/url]\\r\\n"}
13	2019-12-22 17:35:40.769074	Kirshner	\N	{"ContactInfo": "Distributed by:\\r\\nCBS records, inc.\\r\\n51W. 52 Street,\\r\\nNew York, N.Y.\\r\\nU.S.A.\\r\\n"}
14	2019-12-22 17:35:40.784023	Nonesuch	\N	{"Urls": ["http://www.nonesuch.com/", "http://www.facebook.com/NonesuchRecords", "http://twitter.com/NonesuchRecords", "http://instagram.com/nonesuchrecords", "http://www.pinterest.com/nonesuchrecords", "http://plus.google.com/113263488310336800044", "http://www.warnerclassics.com/", "http://en.wikipedia.org/wiki/Nonesuch_Records", "http://soundcloud.com/nonesuchrecords", "http://www.youtube.com/user/nonesuchrecords", "http://vimeo.com/user4071242"], "ContactInfo": "Nonesuch Records\\r\\n1290 Ave of the Americas\\r\\nNew York, NY 10104\\r\\nUSA\\r\\n\\r\\nTel: (212) 707-2900\\r\\nE-Mail: info@nonesuch.com"}
15	2019-12-22 17:35:40.804349	Hollywood Records	\N	{"Urls": ["http://www.hollywoodrecords.com/", "https://www.facebook.com/HollywoodRecords/", "https://twitter.com/HollywoodRecs", "https://www.instagram.com/hollywoodrecords/", "https://giphy.com/hollywoodrecords", "https://www.linkedin.com/company/hollywood-records", "https://open.spotify.com/user/hollywdrecrds", "https://soundcloud.com/hollywoodrecords", "https://www.youtube.com/user/hollywoodrecords", "https://www.youtube.com/channel/UCpPwodiYc4ceaqEBB54trHQ", "https://en.wikipedia.org/wiki/Hollywood_Records"], "ContactInfo": "Hollywood Records\\r\\n500 S. Buena Vista St.\\r\\nOld Team Building,\\r\\nBurbank, CA 91521\\r\\nUSA.\\r\\nPhone: 818-560-5670\\r\\n\\r\\nUK office:\\r\\nHollywood Records Inc.\\r\\nc/o Disney Enterprises Inc.\\r\\n3 Queen Caroline Street, \\r\\nHammersmith, \\r\\nLondon W6 9PE, \\r\\nUnited Kingdom."}
16	2019-12-22 17:35:40.817855	ABC Records	\N	{"Urls": ["http://www.cvinyl.com/labelguides/abc.php", "http://www.bsnpubs.com/abc/", "http://45-sleeves.com/USA/abc/abc-us.htm", "http://en.wikipedia.org/wiki/ABC_Records", "https://books.google.com/books?id=LiUEAAAAMBAJ&printsec=frontcover&dq=billboard+feb+10+1979&hl=en&sa=X&ved=0ahUKEwiakZm_kczbAhXrITQIHYELB4o4ChDoAQhAMAY#v=onepage&q=billboard%20feb%2010%201979&f=false"], "ContactInfo": "[obsolete]\\r\\n-7403, South Western Ave., Chicago 36, Ill. U.S.A.\\r\\n-1321 South Michigan Avenue, Chicago, IL, U.S.A.\\r\\n"}
39	2019-12-22 17:35:41.26312	Paisley Park	\N	{}
40	2019-12-22 17:35:41.269763	Factory	\N	{"Urls": ["http://factoryrecords.org/", "http://www.factoryrecords.info", "http://en.wikipedia.org/wiki/Factory_Records", "http://home.kpn.nl/frankbri/", "http://groups.yahoo.com/group/faclist", "https://www.bookogs.com/credit/176927-factory-records"]}
17	2019-12-22 17:35:40.895049	Island Records	\N	{"Urls": ["http://www.islandrecords.com/", "http://www.facebook.com/IslandRecords", "http://twitter.com/IslandRecords", "http://instagram.com/islandrecords", "http://blog.islandrecords.com/", "http://cvinyl.com/labelguides/island.php", "http://www.islandrecords.co.uk/", "http://www.facebook.com/IslandRecordsUK", "http://twitter.com/islandrecordsuk", "http://instagram.com/islandrecordsuk", "", "http://en.wikipedia.org/wiki/Island_Records", "http://soundcloud.com/islandrecords", "http://www.youtube.com/user/IslandRecordsTV", "http://soundcloud.com/island-records-uk", "http://www.youtube.com/user/islandrecords", "https://www.bookogs.com/credit/226488-island-records"], "ContactInfo": "UMG Headquarters of N.Y.C.\\r\\n1755 Broadway, Floor #29,\\r\\nNew York, NY 10019\\r\\n\\r\\nUMG Headquarters of Santa Monica\\r\\n2220 Colorado Avenue, Floor #5,\\r\\nSanta Monica, CA 90404\\r\\n"}
18	2019-12-22 17:35:40.966799	Columbia Masterworks	\N	{"Urls": ["https://web.archive.org/web/20111119031017/http://ronpenndorf.com:80/labelography2.html", "http://78rpmcommunity.com/colmasterworks/"]}
19	2019-12-22 17:35:40.971465	Vertigo	\N	{"Urls": ["http://vertigoswirl.com", "https://twitter.com/VertigoHQ", "https://en.wikipedia.org/wiki/Vertigo_Records", "https://www.bookogs.com/credit/623748-vertigo-records"]}
20	2019-12-22 17:35:40.991582	Merge Records	\N	{"Urls": ["http://www.mergerecords.com", "http://mergerecords.bandcamp.com", "http://www.epitonic.com/labels/merge-records", "http://www.facebook.com/pages/Merge-Records/88476979019", "http://plus.google.com/117055341735253885831", "http://plus.google.com/101026458701340831651", "http://instagram.com/mergerecords", "http://myspace.com/mergerecords", "http://soundcloud.com/mergerecords", "http://twitter.com/mergerecords", "http://vimeo.com/mergerecords", "http://en.wikipedia.org/wiki/Merge_Records", "http://www.youtube.com/user/MergeRecords", "https://www.posterogs.com/subject/104376-merge-records"], "ContactInfo": "Merge Records \\r\\nPO Box 1235 \\r\\nChapel Hill, NC 27514\\r\\nUSA \\r\\n\\r\\nMailorder Questions: mailorder@mergerecords.com\\r\\nGeneral Information: merge@mergerecords.com"}
21	2019-12-22 17:35:41.001587	Geffen Records	\N	{"Urls": ["http://www.geffen.com/"], "ContactInfo": "[2003-present]\\r\\nGeffen Records\\r\\n2220 Colorado Ave\\r\\nSanta Monica, CA 90404\\r\\n\\r\\n[1994-1999]\\r\\nGeffen Records\\r\\n9130 Sunset Blvd.\\r\\nLos Angeles, CA 90069-6197\\r\\n\\r\\n9126 Sunset Blvd.\\r\\nLos Angeles, Calif. 90069\\r\\n"}
22	2019-12-22 17:35:41.005324	Go! Beat	\N	{}
23	2019-12-22 17:35:41.024875	Stones Throw Records	\N	{"Urls": ["http://www.stonesthrow.com/", "http://www.facebook.com/stonesthrow", "http://twitter.com/stonesthrow", "http://twitter.com/StonesThrowJP", "http://instagram.com/stonesthrow", "http://myspace.com/stonesthrow", "http://stonesthrow.tumblr.com/", "http://en.wikipedia.org/wiki/Stones_Throw_Records", "http://www.epitonic.com/labels/stones-throw-records/", "http://soundcloud.com/stonesthrow", "http://www.youtube.com/user/stonesthrow", "http://www.youtube.com/user/stonesthrowradio", "http://vimeo.com/stonesthrow"], "ContactInfo": "Stones Throw Records\\r\\n2658 Griffith Park Blvd. #504\\r\\nLos Angeles CA 90039-2520\\r\\nUSA\\r\\nlosangeles@stonesthrow.com\\r\\n\\r\\nEurope: zena@stonesthrow.com\\r\\nJapan: kota@stonesthrow.com \\r\\n\\r\\nContact info circa 1997:\\r\\n2228 S. El Camino Real #260\\r\\nSan Mateo, CA 94403\\r\\n(408) 631-3012\\r\\n(415) 343-6801 (fax)"}
24	2019-12-22 17:35:41.030826	ISO Records	\N	{}
25	2019-12-22 17:35:41.044027	Domino	\N	{"Urls": ["http://www.dominorecordco.com/", "http://www.facebook.com/DominoRecordCo", "http://twitter.com/Dominorecordco", "http://labelsbase.net/label/domino", "http://vine.co/u/938782277100511232", "http://instagram.com/dominorecordco", "http://plus.google.com/+DominoRecordingCo", "http://myspace.com/dominorecords", "http://soundcloud.com/dominorecordco", "http://www.mixcloud.com/Domino_Radio/", "http://www.youtube.com/DominoRecords", "http://vimeo.com/dominorecordco", "http://www.dailymotion.com/dominorecordco", "http://en.wikipedia.org/wiki/Domino_Recording_Company"]}
26	2019-12-22 17:35:41.051375	20th Century Records	\N	{"ContactInfo": "20th Century Records\\r\\n8544 Sunset Blvd. \\r\\nLos Angeles\\r\\nCalifornia 90069\\r\\n"}
27	2019-12-22 17:35:41.056094	Universal Republic Records	\N	{"Urls": ["http://www.universalmusic.com/"], "ContactInfo": "Universal Republic Records\\r\\n1755 Broadway\\r\\nNew York, NY 10019"}
28	2019-12-22 17:35:41.069246	Constellation	\N	{"Urls": ["http://cstrecords.com/", "http://www.facebook.com/cstrecords", "http://twitter.com/cstrecords", "http://en.wikipedia.org/wiki/Constellation_Records_(Canada)", "http://soundcloud.com/constellation-records", "http://www.youtube.com/user/cstrecords1", "http://vimeo.com/cstrecords", "http://vimeo.com/channels/constellation", "https://constellation.bandcamp.com"], "ContactInfo": "p.o. box 55012\\r\\nCSP Fairmount\\r\\nMontréal QC\\r\\nCanada H2T 3E2\\r\\ninfo@cstrecords.com\\r\\nFAX: 514.279.9705\\r\\nTEL: 253.736.1966\\r\\n"}
29	2019-12-22 17:35:41.073519	EMI America	\N	{"Urls": ["http://www.emigroup.com/", "https://en.wikipedia.org/wiki/EMI_America_Records"]}
30	2019-12-22 17:35:41.127616	Fiction Records	\N	{"Urls": ["http://www.fictionrecords.co.uk", "http://www.dailymotion.com/fictionrecords", "http://www.facebook.com/FictionRecords", "http://www.flickr.com/photos/fictionrecords", "http://instagram.com/fictionrecords", "http://myspace.com/fictionrecords", "http://soundcloud.com/fictionrecords", "http://twitter.com/FictionRecords", "http://vimeo.com/user4917876", "http://vine.co/u/1119257713835204608", "http://en.wikipedia.org/wiki/Fiction_Records", "http://www.youtube.com/user/fictionrecords"], "ContactInfo": "165 / 169 High Road, Willesden,\\r\\nLondon NW10 England"}
31	2019-12-22 17:35:41.132118	MBV Records	\N	{"Urls": ["http://www.mybloodyvalentine.org/"], "ContactInfo": "\\r\\n"}
32	2019-12-22 17:35:41.139759	TBD Records	\N	{"Urls": ["http://www.tbdrecords.com/", "http://blog.tbdrecords.com/", "http://www.facebook.com/tbdrecords", "http://twitter.com/tbdrecords", "https://en.wikipedia.org/wiki/TBD_Records"], "ContactInfo": "TBD Records\\r\\n8439 Sunset Blvd.\\r\\nWest Hollywood, CA 90069\\r\\nUSA"}
33	2019-12-22 17:35:41.144433	Big Brother	\N	{}
34	2019-12-22 17:35:41.152413	Sire	\N	{"Urls": ["http://www.sirerecords.com/", "http://en.wikipedia.org/wiki/Sire_Records", "http://www.youtube.com/user/SireRecords"], "ContactInfo": "Sire Records\\r\\n75 Rockefeller Plaza\\r\\nNew York, NY 10019-6908\\r\\nUSA\\r\\n"}
35	2019-12-22 17:35:41.202424	Modular Recordings	\N	{"Urls": ["http://modularrecordings.com/", "http://www.facebook.com/modularpeople", "http://twitter.com/modularpeople", "http://instagram.com/modularpeople", "http://myspace.com/modularpeople", "http://en.wikipedia.org/wiki/Modular_Recordings", "http://soundcloud.com/modularpeople", "http://www.youtube.com/user/modularpeople", "http://vimeo.com/modularpeople"], "ContactInfo": "Modular Recordings\\r\\nPO Box 1666\\r\\nDarlinghurst NSW 1300\\r\\nAustralia"}
36	2019-12-22 17:35:41.207635	Ode Records (2)	\N	{"Urls": ["http://www.onamrecords.com/Ode_Records.html", "http://www.bsnpubs.com/aandm/ode.html"]}
37	2019-12-22 17:35:41.213095	Volcano (2)	\N	{"Urls": ["http://www.zombalabelgroup.com"]}
38	2019-12-22 17:35:41.259054	Capricorn Records	\N	{"Urls": ["http://www.bsnpubs.com/atlantic/capricorn.html", "https://www.thefreelibrary.com/Mercury+forms+joint+venture+with+Capricorn+Records.-a018258523"], "ContactInfo": "Capricorn Records\\r\\n535 Cotton Avenue, Macon, Georgia 31201, United States\\r\\n(defunct)\\r\\n\\r\\n[1994]\\r\\nCapricorn Records\\r\\n120 30th Avenue North\\r\\nNashville, TN 37208"}
41	2019-12-22 17:35:41.286904	London Records	\N	{"Urls": ["http://londonrecords.org", "http://wikipedia.org/wiki/London_Records", "http://www.youtube.com/channel/UCpDPOKeVLYSvIAtgmkwVAAA", "https://www.bookogs.com/credit/487163-london-records-limited", "https://www.filmo.gs/company/315230-london-records"], "ContactInfo": "UK office:\\r\\nLondon Records Ltd.\\r\\nPO Box 2LB\\r\\nLondon W1A 2LB\\r\\nUNITED KINGDOM\\r\\n\\r\\nCanadian office:\\r\\nLondon Records of Canada\\r\\n6265 Côte de Liesse\\r\\nSt Laurent, PQ H4T 103\\r\\nCANADA"}
42	2019-12-22 17:35:41.384389	Columbia	\N	{"Urls": ["http://www.columbiarecords.com", "http://www.columbia.co.uk", "http://www.facebook.com/columbiarecords", "http://www.facebook.com/ColumbiaRecordsUK", "http://www.facebook.com/columbiafrance", "http://twitter.com/ColumbiaRecords", "http://twitter.com/ColumbiaUK", "http://twitter.com/columbia_fr", "http://vine.co/u/921185004330037248", "http://vine.co/u/911313041604358144", "http://vine.co/u/939651343977680896", "http://instagram.com/columbiarecords", "http://instagram.com/columbiauk", "http://instagram.com/columbiafrance", "http://www.pinterest.com/columbiarecords", "http://www.pinterest.com/columbiauk", "http://www.pinterest.com/columbiafrance", "http://myspace.com/columbiarecords", "http://myspace.com/icolumbia", "http://myspace.com/columbiafrance", "http://plus.google.com/113244911644311727918", "http://plus.google.com/+columbiarecordsuk", "http://plus.google.com/115207797830593524022", "http://columbiarecordsnews.tumblr.com", "http://columbiauk.tumblr.com", "http://fischer.hosting.paran.com/music/emi-lps/emi-columbia-uk-sax-intro.htm", "http://heroinc.0catch.com/columbia", "http://www.vinylbeat.com/cgi-bin/labelfocus.cgi?label=COLUMBIA&label_section=A,B,C", "http://en.wikipedia.org/wiki/Columbia_Records", "http://www.imdb.com/company/co0064761", "http://soundcloud.com/columbiarecords", "http://soundcloud.com/columbia-records", "http://soundcloud.com/columbia-records-uk", "http://soundcloud.com/columbiaweb", "http://www.youtube.com/user/columbiarecords", "http://www.youtube.com/user/icolumbia", "http://www.youtube.com/user/columbiaweb", "http://vimeo.com/columbiarecords", "http://www.globaldogproductions.info/c/cbs-lps-us.html", "https://londonjazzcollector.wordpress.com/record-labels-guide/columbia-records/columbia-us-labels"], "ContactInfo": "USA:\\r\\n1965-1988: 51 West 52nd Street, New York, NY 10019, U.S.A., Phone (212) 445-4321\\r\\n1988-2016: 550 Madison Avenue, New York, NY 10022, U.S.A.\\r\\nfrom 2016: 25 Madison Avenue, New York, NY 10010, U.S.A., Phone (212) 833-8000\\r\\n\\r\\nUK: \\r\\n9 Derry Street \\r\\nKensington \\r\\nLondon W8 5HY \\r\\nUK \\r\\n"}
43	2019-12-22 17:35:41.406278	DGC	\N	{"Urls": ["www.geffen.com"], "ContactInfo": "DGC\\r\\n9130 Sunset Blvd.\\r\\nLos Angeles, CA 90069-6197"}
44	2019-12-22 17:35:41.41179	Modern Records	\N	{"ContactInfo": "9111 Sunset Boulevard \\r\\nLos Angeles \\r\\nCalifornia 90069\\r\\n"}
45	2019-12-22 17:35:41.422975	MCA Records	\N	{"Urls": ["http://www.cvinyl.com/labelguides/mca.php", "http://45-sleeves.com/USA/mca/mca-us.htm", "http://45-sleeves.com/UK/mca/mca-uk.htm", "http://www.collectable-records.ru/labels/E_M/M.C.A/", "http://en.wikipedia.org/wiki/MCA_Records", "http://www.imdb.com/company/co0042246/", "https://www.americanradiohistory.com/hd2/IDX-Business/Music/Archive-Billboard-IDX/IDX/70s/1973/Billboard%201973-09-29-OCR-Page-0003.pdf", "https://www.bookogs.com/credit/44879-mca-records"], "ContactInfo": "MCA Records\\r\\n2220 Colorado Ave\\r\\nSanta Monica, CA 90404\\r\\n\\r\\nUK Address:\\r\\n72/74 Brewer Street\\r\\nLondon\\r\\nW1R3PH"}
46	2019-12-22 17:35:41.439123	Warner Bros. Records	\N	{"Urls": ["http://www.warnerbrosrecords.com/", "http://www.facebook.com/WarnerBrosRecords", "http://plus.google.com/u/0/+warnerbrosrecords/about", "http://www.myspace.com/warnerbrosrecords", "http://soundcloud.com/warnerbrosrecords", "http://twitter.com/wbr", "http://www.youtube.com/user/warnerbrosrecords", "http://en.wikipedia.org/wiki/Warner_Bros._Records", "http://www.bsnpubs.com/warner/warnerstory.html", "http://www.vinylbeat.com/cgi-bin/labelfocus.cgi?label=WARNER+BROS.+%28WB%29&label_section=V,W,X", "https://www.bookogs.com/credit/396650-warner-bros-records", "https://www.filmo.gs/company/245024-warner-bros-records", "https://www.posterogs.com/credit/6604-warner-brothers-records"], "ContactInfo": "3300 Warner Boulevard\\r\\nBurbank, CA 91505-4964\\r\\nUSA\\r\\n\\r\\n1290 Avenue of the Americas\\r\\nNew York, NY 10104-0012\\r\\nUSA\\r\\n\\r\\n(818) 846-9090\\r\\n"}
47	2019-12-22 17:35:41.454543	4AD	\N	{"Urls": ["http://www.4ad.com/", "http://www.facebook.com/fourad", "http://twitter.com/4AD_Official", "http://instagram.com/4ad", "http://plus.google.com/+4ad_official", "http://tumblr.4ad.com/", "http://eyesore.no/", "http://www.fedge.net/ftww/", "http://pages.infinit.net/saum/4ad/", "http://en.wikipedia.org/wiki/4AD", "http://www.youtube.com/user/4ADRecords", "https://www.bookogs.com/credit/282135-4ad", "https://4adofficial.bandcamp.com/"], "ContactInfo": "[b]UK office:[/b]\\r\\n4AD\\r\\n17-19 Alma Road\\r\\nLondon, SW18 1AA\\r\\nUnited Kingdom\\r\\n\\r\\n4ad@4ad.com\\r\\n\\r\\n[b]US office:[/b]\\r\\n4AD\\r\\n625 Broadway, 12th Floor\\r\\nNew York, NY 10012\\r\\nUSA"}
48	2019-12-22 17:35:41.459377	Run The Jewels, Inc.	\N	{}
49	2019-12-22 17:35:41.466926	Triple Crown Records	\N	{"Urls": ["http://www.triplecrownrecords.com"], "ContactInfo": "Triple Crown Records\\r\\n331 West 57th St #472 \\r\\nNew York, NY 10019\\r\\nUSA\\r\\n\\r\\ninfo@triplecrownrecords.com\\r\\n"}
50	2019-12-22 17:35:41.483863	Tamla	\N	{"Urls": ["http://www.bsnpubs.com/motown/tamla/tamla.html", "http://www.bsnpubs.com/motown/tmg.html"]}
51	2019-12-22 17:35:41.493583	Reprise Records	\N	{"Urls": ["http://www.repriserecords.com", "http://bsnpubs.com/warner/reprise/reprisestory.html", "http://globaldogproductions.info/r/reprise.html", "http://www.vinylbeat.com/cgi-bin/labelfocus.cgi?label=REPRISE&label_section=P,Q,R", "https://en.wikipedia.org/wiki/Reprise_Records"], "ContactInfo": "Reprise Records\\r\\n3300 Warner Blvd.\\r\\nBurbank, CA 91505-4694\\r\\nU.S.A.\\r\\n\\r\\nReprise Records\\r\\n75 Rockefeller Plaza\\r\\nNew York, NY 10019-6908\\r\\nU.S.A."}
52	2019-12-22 17:35:41.503306	Apple Records	\N	{"Urls": ["http://www.applerecords.com/", "http://www.applecorpsltd.com/", "http://www.thebeatles.com/", "https://www.bookogs.com/credit/44866-apple-records"], "ContactInfo": "27 Ovington Square, \\r\\nLondon SW3 1LJ\\r\\nUNITED KINGDOM\\r\\n\\r\\nTel: 020 7761 9600 \\r\\nFax: 020 7225 0661\\r\\n"}
53	2019-12-22 17:35:41.517186	RCA	\N	{"Urls": ["http://www.rcarecords.com/", "http://historysdumpster.blogspot.co.uk/2012/08/rca-colour-record-labels-of-70s.html", "https://www.bookogs.com/credit/535946-rca"], "ContactInfo": "[u]US:[/u]\\r\\n550 Broadway\\r\\nNew York, NY 10022-3211\\r\\n(212) 833-6200\\r\\n\\r\\nRCA Records\\r\\n1540 Broadway\\r\\nNew York, NY 10036\\r\\n\\r\\n[u]France:[/u]\\r\\n9 Avenue Matignon\\r\\n75008 Paris\\r\\nFrance\\r\\n\\r\\n[u]Spain:[/u]\\r\\nRCA SA\\r\\nDoctor Fleming, 43\\r\\nMadrid-16\\r\\n"}
54	2019-12-22 17:35:41.52494	Glassnote (2)	\N	{"Urls": ["http://glassnotemusic.com", "http://www.facebook.com/glassnote", "http://instagram.com/glassnotemusic", "http://soundcloud.com/glassnotemusic", "http://twitter.com/glassnotemusic", "http://en.wikipedia.org/wiki/Glassnote_Records", "http://www.youtube.com/user/Glassnoterecords"]}
55	2019-12-22 17:35:41.540103	Brainfeeder	\N	{"Urls": ["http://www.brainfeedersite.com", "http://ninjatune.net/shop/labels/brainfeeder", "http://www.facebook.com/pages/BRAINFEEDER/117839439630", "http://myspace.com/brainfeeder", "http://soundcloud.com/brainfeeder", "http://twitter.com/BRAINFEEDER", "http://vimeo.com/brainfeeder", "http://vimeo.com/channels/brainfeeder", "http://vk.com/brainfeeder", "http://www.youtube.com/user/Brainfeedermedia", "http://www.alphapuprecords.com/labelpage.php?LabelID=5", "http://en.wikipedia.org/wiki/Brainfeeder"]}
56	2019-12-22 17:35:41.567446	Matador	\N	{"Urls": ["http://www.matadorrecords.com/", "http://www.facebook.com/MatadorRecords", "http://twitter.com/matadorrecords", "http://instagram.com/matadorrecords", "http://myspace.com/matadorrecords", "http://plus.google.com/+matadorrecs", "http://matadorrecords.tumblr.com/", "http://store.matadorrecords.com/", "http://en.wikipedia.org/wiki/Matador_Records", "http://www.epitonic.com/labels/matador-records/", "http://soundcloud.com/matadorrecs", "http://www.youtube.com/user/matadorrecs", "http://vimeo.com/user2100285", "http://web.archive.org/web/20080917000836/www.arancidamoeba.com/mrr/whatsamatador.html", "https://matadorrecords.bandcamp.com/", "https://www.posterogs.com/subject/95399-matador"], "ContactInfo": "First address: 611 Broadway, Suite 712, New York, NY 10012\\r\\n\\r\\nSecond address: 676 Broadway, 12th Floor, New York, NY 10012\\r\\n\\r\\nThird address: 625 Broadway, 12th Floor, New York, NY 10012                \\r\\n\\r\\nCurrent address:\\r\\n\\r\\n304 Hudson Street, 7th Floor\\r\\nNew York, NY 10013\\r\\n212-995-5882 phone\\r\\n212-995-5883 fax\\r\\n\\r\\nUK:\\r\\n\\r\\nMatador Records Ltd.\\r\\n17-19 Alma Road\\r\\nLondon\\r\\nSW18 1AA\\r\\nUnited Kingdom\\r\\n020-8875-6200 phone\\r\\n020-8871-1766 fax\\r\\n\\r\\nMatador Records Ltd.\\r\\n14 St. Marks Road\\r\\nLondon\\r\\nW11 1RQ\\r\\nUnited Kingdom\\r\\n"}
57	2019-12-22 17:35:41.577842	Harvest	\N	{"Urls": ["http://www.harvestrecords.com/", "http://www.facebook.com/HarvestRecords", "http://twitter.com/harvest_records", "http://instagram.com/harvestrecords", "http://myspace.com/harvestrecords", "http://harvestrecords.tumblr.com/", "http://www.myplaydirect.com/harvest-records", "http://en.wikipedia.org/wiki/Harvest_Records", "http://soundcloud.com/harvestrecords", "http://noisetrade.com/harvestrecords", "http://www.youtube.com/user/harvestrecordings"]}
58	2019-12-22 17:35:41.588907	Parlophone	\N	{"Urls": ["http://www.parlophone.co.uk/", "http://www.globaldogproductions.info/p/parlophone-uk4000.html", "http://www.facebook.com/parlophone", "http://twitter.com/parlophone", "http://vine.co/u/909881773838708736", "http://instagram.com/parlophone", "http://myspace.com/parlophone", "http://plus.google.com/+ParlophoneCoUk", "http://parlophone.tumblr.com/", "http://en.wikipedia.org/wiki/Parlophone", "http://soundcloud.com/parlophone", "http://www.youtube.com/user/ParlophoneRecords", "http://www.youtube.com/user/parlophone"]}
59	2019-12-22 17:35:41.592223	Rolling Stones Records	\N	{}
60	2019-12-22 17:35:41.606717	Chrysalis	\N	{"Urls": ["http://chrysalisrecordings.com", "https://www.blueraincoatmusic.com/chrysalisrecords/", "http://www.facebook.com/ChrysalisRecs", "http://twitter.com/ChrysalisRecs", "http://www.instagram.com/chrysalisrecs", "http://soundcloud.com/ChrysalisRecs", "http://en.wikipedia.org/wiki/Chrysalis_Records", "http://www.cvinyl.com/labelguides/chrysalis.php", "http://www.youtube.com/channel/UCLtyEiTS8AEZFuizOcq-NwA"], "ContactInfo": "Blue Raincoat Music | Chrysalis Records\\r\\nUnit 304 \\r\\nWestbourne Studios\\r\\n242 Acklam Road\\r\\nLondon\\r\\nW10 5JJ\\r\\nUK \\r\\n\\r\\nPhone: +44 (0)20 3735 5632. \\r\\nEmail: chrysalis@blueraincoatmusic.com\\r\\n\\r\\n(Obsolete:\\r\\n\\r\\nThe Chrysalis Building \\r\\nBramley Road \\r\\nLondon \\r\\nW10 6SP \\r\\nUK \\r\\n\\r\\nPhone: +44 (0)20 7221 2213.\\r\\nEmail: info@chrysalismusic.co.uk)"}
61	2019-12-22 17:35:41.612043	RSO	\N	{"Urls": ["http://en.wikipedia.org/wiki/RSO_Records"]}
62	2019-12-22 17:35:41.61964	EMI	\N	{"Urls": ["http://www.emimusic.com/about/history/timeline/", "http://www.emimusic.com/about/history/", "http://www.emimusic.com", "https://en.wikipedia.org/wiki/EMI", "http://www.facebook.com/EMIGroup", "http://twitter.com/emimusic", "https://www.bookogs.com/credit/39749-emi"]}
63	2019-12-22 17:35:41.631818	Fantasy	\N	{"Urls": ["http://www.concordmusicgroup.com/labels/Fantasy/", "http://en.wikipedia.org/wiki/Fantasy_Records", "http://www.bsnpubs.com/fantasy/fantasy/01fantasy-10.html", "https://oac.cdlib.org/findaid/ark:/13030/c87p946b/entire_text/"], "ContactInfo": "Concord Records, Inc.\\r\\n270 North Canon Drive, #1212\\r\\nBeverly Hills, CA. 90210\\r\\nPhone (310) 385-4455\\r\\nFax (310) 385-4466\\r\\n\\r\\nOriginal primary address:\\r\\nFantasy Records\\r\\n10th And Parker\\r\\nBerkeley, CA 94710\\r\\nUSA\\r\\n"}
64	2019-12-22 17:35:41.644491	Third Man Records	\N	{"Urls": ["http://www.thirdmanrecords.com", "http://thirdmanstore.com/", "http://www.facebook.com/ThirdManRecords", "http://twitter.com/thirdmanrecords", "http://thirdmanrecordsofficial.tumblr.com/", "http://instagram.com/thirdmanrecordsofficial", "http://www.myspace.com/thirdmanrecords", "http://en.wikipedia.org/wiki/Third_Man_Records", "https://soundcloud.com/thirdmanrecords", "http://www.youtube.com/user/OfficialTMR", "http://vimeo.com/user6252903"], "ContactInfo": "623 7th Avenue South\\r\\nNasvhille, TN 37203\\r\\n"}
65	2019-12-22 17:35:41.654798	Asthmatic Kitty Records	\N	{"Urls": ["http://www.asthmatickitty.com/", "http://www.facebook.com/asthmatickitty", "http://twitter.com/asthmatickitty", "http://www.flickr.com/photos/asthmatickitty/", "http://en.wikipedia.org/wiki/Asthmatic_Kitty", "http://soundcloud.com/asthmatickitty", "http://asthmatickitty.bandcamp.com/", "http://www.noisetrade.com/asthmatickittyrecords", "http://www.youtube.com/user/AsthmaticKitty", "http://vimeo.com/asthmatickitty"], "ContactInfo": "Asthmatic Kitty Records\\r\\nPost Office Box 1282\\r\\nLander, WY 82520 USA\\r\\ninfo@asthmatickitty.com\\r\\n"}
66	2019-12-22 17:35:41.668592	Jagjaguwar	\N	{"Urls": ["http://www.jagjaguwar.com", "https://jagjaguwar.bandcamp.com/", "http://soundcloud.com/jagjaguwar", "http://www.facebook.com/Jagjaguwar", "http://instagram.com/jagjaguwarinc", "http://twitter.com/jagjaguwar", "http://jagjaguwarinc.tumblr.com", "http://www.youtube.com/user/jagjaguwarinc", "http://www.youtube.com/user/SecretlyJag", "http://en.wikipedia.org/wiki/Jagjaguwar"], "ContactInfo": "JAGJAGUWAR\\r\\n1499 West 2nd Street\\r\\nBloomington, IN 47403\\r\\nUSA \\r\\n\\r\\ninfo@jagjaguwar.com\\r\\n\\r\\n(1997)\\r\\nJagjaguwar\\r\\nPO Box 136\\r\\nCharlottesville, VA 22902-0136"}
67	2019-12-22 17:35:41.684834	XL Recordings	\N	{"Urls": ["http://xlrecordings.com/", "https://www.facebook.com/xlrecordings", "https://twitter.com/XLRECORDINGS", "https://instagram.com/xlrecordings/", "http://myspace.com/xlrecordingsmusic", "http://plus.google.com/+xlrecordings", "http://xlrecordings.tumblr.com/", "https://www.youtube.com/user/XLRecordings", "http://www.ustream.tv/xlrecordings"], "ContactInfo": "1 Codrington Mews           \\r\\nLondon, W11 2EH\\r\\nUK\\r\\nTel: 020 8870 7511\\r\\nFax: 020 8875 6246\\r\\ne-mail: xl@xl-recordings.com\\r\\n\\r\\n304 Hudson Street, 7th Floor\\r\\nNew York, 10013\\r\\nUSA\\r\\ne-mail: xl@xl-recordings.com\\r\\n\\r\\nFormer address (at least in 1991):\\r\\n17-19 Alma Road\\r\\nLondon, SW18 1AA\\r\\nUK\\r\\nTel: 081 7511\\r\\nFax: 081 4178"}
68	2019-12-22 17:35:41.689269	Death Waltz Recording Company	\N	{"ContactInfo": "@deathwaltzrecs "}
69	2019-12-22 17:35:41.695426	Arista	\N	{"Urls": ["https://twitter.com/aristarecords", "http://en.wikipedia.org/wiki/Arista_Records", "https://www.posterogs.com/subject/101821-arista"]}
70	2019-12-22 17:35:41.73518	Atlantic	\N	{"Urls": ["http://www.atlanticrecords.com", "http://www.atlanticrecords.co.uk", "http://www.bsnpubs.com/atlantic", "http://www.spinalflow.com/atlantic.htm", "http://www.facebook.com/atlanticrecords", "http://www.facebook.com/AtlanticRecordsUK", "http://plus.google.com/+atlanticrecords", "http://plus.google.com/103312453134275685008", "http://www.imdb.com/company/co0136813", "http://instagram.com/atlanticrecords", "http://instagram.com/atlanticrecordsuk", "http://myspace.com/atlanticrecords", "http://myspace.com/atlanticrecordsuk", "http://www.pinterest.com/atlrecordpromo", "http://www.pinterest.com/AtlanticRcrdsUK", "http://soundcloud.com/atlanticrecords", "http://soundcloud.com/atlantic-records-uk", "http://atlanticrecords.tumblr.com", "http://atlanticrecordsuk.tumblr.com", "http://twitter.com/AtlanticRecords", "http://twitter.com/AtlanticRcrdsUK", "http://vimeo.com/user5091145", "http://vimeo.com/user2212209", "http://vine.co/atlanticrecords", "http://vine.co/u/936708264274579456", "http://en.wikipedia.org/wiki/Atlantic_Records", "http://en.wikipedia.org/wiki/Atlantic_Records_UK", "http://www.youtube.com/user/AtlanticVideos", "http://www.youtube.com/user/atlanticrecords", "http://www.youtube.com/user/atlanticrecordsTV", "http://www.cvinyl.com/labelguides/atlantic.php", "https://www.bookogs.com/credit/44867-atlantic-records"], "ContactInfo": "1947-1948: 208 W 56th St., New York, NY 10019, U.S.A.\\r\\n1948-1951: 301 W 54th St., New York, NY 10019, U.S.A.\\r\\n1951-1956: 234 W 56th St., New York, NY 10019, U.S.A.\\r\\n1956-1961: 157 W 57th St., New York, NY 10019, U.S.A.\\r\\n1961-1973: 1841 Broadway, New York, NY 10023, U.S.A.\\r\\n1973-2014: 75 Rockefeller Plaza, New York, NY 10019, U.S.A.\\r\\n1999-2014: 1290 Avenue Of The Americas, New York, NY 10104, U.S.A.\\r\\n(Contact info now obsolete)\\r\\n\\r\\n1633 Broadway\\r\\nNew York, NY 10019\\r\\nU.S.A.\\r\\nPhone: (212) 707-2000"}
71	2019-12-22 17:35:41.755963	Warp Records	\N	{"Urls": ["http://warp.net", "http://warpmusic.com", "http://www.facebook.com/warprecords", "http://www.facebook.com/warpfrance", "http://facebook.com/warpmusicpub", "http://instagram.com/warprecords", "http://instagram.com/marinewarp", "http://myspace.com/warprecords", "http://soundcloud.com/warp-records", "http://soundcloud.com/warp-publishing", "http://warprecords.tumblr.com", "http://twitter.com/WarpRecords", "http://twitter.com/warpbot", "http://twitter.com/warpfrance", "http://twitter.com/marinewarp", "http://twitter.com/warpmusicpub", "http://vimeo.com/warprecords", "http://en.wikipedia.org/wiki/Warp_(record_label)", "http://youtube.com/user/warprecords", "http://www.epitonic.com/labels/warp-records", "https://web.archive.org/web/20090504081414/www.warprecords.com", "https://www.bookogs.com/credit/257494-warp-records"], "ContactInfo": "[i](current)[/i] \\r\\nWarp Records \\r\\nPO Box 25378 \\r\\nLondon NW5 1GL \\r\\nUK \\r\\n\\r\\n[i](obsolete)[/i] \\r\\nWarp Records \\r\\nPO Box 474 \\r\\nSheffield \\r\\nS1 3BW\\r\\nUK \\r\\n\\r\\n[i](obsolete)[/i] \\r\\ntel: +44 (0)742 757586 \\r\\nfax: +44 (0)742 757589 \\r\\n"}
72	2019-12-22 17:35:41.76431	Discipline Global Mobile	\N	{"Urls": ["http://www.dgmlive.com/", "https://www.burningshed.com/store/panegyric/product/340/1948/"], "ContactInfo": "Discipline Global Mobile, Ltd.\\r\\nPO Box 5282\\r\\nBeverly Hills, CA 90209\\r\\nUSA\\r\\n"}
73	2019-12-22 17:35:41.773603	Music On Vinyl	\N	{"Urls": ["http://www.musiconvinyl.com", "http://www.facebook.com/musiconvinyl", "http://plus.google.com/+MusicOnVinyl180", "http://instagram.com/musiconvinyl", "http://www.pinterest.com/musiconvinyl", "http://soundcloud.com/music-on-vinyl", "http://twitter.com/MusicOnVinyl", "http://www.youtube.com/user/themusiconvinyl"], "ContactInfo": "Music On Vinyl\\r\\nPO Box 9554\\r\\n2003 LN Haarlem\\r\\nThe Netherlands\\r\\n\\r\\nE-Mail: info[at]musiconvinyl.com"}
74	2019-12-22 17:35:41.77803	Experience Hendrix	\N	{}
75	2019-12-22 17:35:41.789311	Sub Pop	\N	{"Urls": ["http://www.subpop.com", "http://subpop.bandcamp.com", "http://www.epitonic.com/labels/sub-pop-records", "http://www.facebook.com/subpoprecords", "http://plus.google.com/+subpop", "http://instagram.com/subpop", "http://myspace.com/subpoprecords", "http://www.pinterest.com/subpoprecords", "http://soundcloud.com/subpop", "http://subpop.tumblr.com", "http://twitter.com/subpop", "http://vimeo.com/subpop", "http://en.wikipedia.org/wiki/Sub_Pop", "http://www.youtube.com/user/subpoprecords2"], "ContactInfo": "2013 Fourth Avenue\\r\\nThird Floor\\r\\nSeattle, WA, 98121 USA\\r\\n\\r\\nwork (206)441-8441\\r\\nfax    (206)441-8245\\r\\n\\r\\nPRESS CONTACT\\r\\npress@subpop.com\\r\\n\\r\\nGENERAL INFORMATION\\r\\ninfo@subpop.com\\r\\n"}
76	2019-12-22 17:35:41.794917	Top Dawg Entertainment	\N	{"Urls": ["http://www.tde.us/", "http://soundcloud.com/topdawgent", "http://www.youtube.com/topdawgentTDE", "http://www.twitter.com/topdawgent"]}
77	2019-12-22 17:35:41.804821	Elektra	\N	{"Urls": ["http://www.elektra.com/", "http://www.elektra60.com/", "http://www.atlanticrecords.com/", "http://www.wmg.com", "http://www.bsnpubs.com/elektra/", "http://www.facebook.com/Elektra", "http://www.youtube.com/elektrarecords", "http://www.instagram.com/elektrarecords", "https://twitter.com/elektrarecords", "https://en.wikipedia.org/wiki/Elektra_Records"], "ContactInfo": "75 Rockefeller Plaza, New York\\r\\nNY 10019\\r\\nUSA\\r\\n\\r\\n345 N. Maple Drive, Beverly Hills\\r\\nCA 90210\\r\\nUSA"}
78	2019-12-22 17:35:41.815496	Asylum Records	\N	{"Urls": ["http://www.asylumrecords.com/", "http://www.facebook.com/pages/Asylum-Records/109310352428349", "http://twitter.com/AsylumRecs", "http://en.wikipedia.org/wiki/Asylum_Records", "http://www.bsnpubs.com/elektra/asylumstory.html"], "ContactInfo": "Asylum Records\\r\\n1290 Avenue of the Americas, 24th Floor\\r\\nNew York, NY 10104\\r\\nUSA\\r\\n\\r\\nAsylum Records\\r\\n1906 Acklen Ave.\\r\\nNashville, TN 37212\\r\\nPhone: (615) 292-7990\\r\\nFax: (615) 292-8219"}
79	2019-12-22 17:35:41.820509	Ticker Tape Ltd.	\N	{"Urls": ["https://en.wikipedia.org/wiki/Ticker_Tape"]}
80	2019-12-22 17:35:41.829723	Rough Trade	\N	{"Urls": ["http://www.roughtraderecords.com/", "http://www.facebook.com/roughtraderecords", "http://twitter.com/RoughTradeRecs", "http://twitter.com/RoughTradeLab", "http://instagram.com/roughtraderecords", "http://myspace.com/roughtraderecords", "http://en.wikipedia.org/wiki/Rough_Trade_Records", "http://soundcloud.com/roughtraderecords", "http://www.youtube.com/user/RoughTradeRecordsUK", "https://www.bookogs.com/credit/144061-rough-trade"]}
81	2019-12-22 17:35:41.842512	Epic	\N	{"Urls": ["http://www.epicrecords.com/", "http://www.facebook.com/epicrecords", "http://instagram.com/EpicRecords#", "http://myspace.com/epicrecords", "http://epicrecords.tumblr.com/", "http://twitter.com/Epic_Records", "http://www.youtube.com/user/EpicRecords", "http://en.wikipedia.org/wiki/Epic_Records", "http://www.epic-jp.net/", "http://en.wikipedia.org/wiki/Epic/Sony_Records", "http://www.vinylbeat.com/cgi-bin/labelfocus.cgi?label=EPIC&label_section=D,E,F", "http://logos.wikia.com/wiki/Epic_Records", "http://www.cvinyl.com/labelguides/epic.php"], "ContactInfo": "[2007]\\r\\nEpic\\r\\nA Division of Sony BMG Music Entertainment\\r\\n550 Madison Avenue\\r\\nNew York, NY 10022-3211"}
\.


--
-- Data for Name: library; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.library (user_id, track_id) FROM stdin;
2	1
2	2
2	3
2	4
2	5
2	6
2	7
2	8
2	9
2	10
2	11
2	12
2	13
2	14
2	15
2	16
2	17
2	18
2	19
2	20
2	21
2	22
2	23
2	24
2	25
2	26
2	27
2	28
2	29
2	100
2	101
2	102
2	103
2	104
2	105
2	106
2	107
2	108
2	109
2	110
2	111
2	112
2	113
2	114
2	115
2	116
2	117
2	118
2	119
2	120
2	121
2	122
2	123
2	124
2	125
2	126
2	127
2	128
2	129
2	200
2	201
2	202
2	203
2	204
2	205
2	206
2	207
2	208
2	209
2	210
2	211
2	212
2	213
2	214
2	215
2	216
2	217
2	218
2	219
2	220
2	221
2	222
2	223
2	224
2	225
2	226
2	227
2	228
2	229
2	300
2	301
2	302
2	303
2	304
2	305
2	306
2	307
2	308
2	309
2	310
2	311
2	312
2	313
2	314
2	315
2	316
2	317
2	318
2	319
2	320
2	321
2	322
2	323
2	324
2	325
2	326
2	327
2	328
2	329
2	400
2	401
2	402
2	403
2	404
2	405
2	406
2	407
2	408
2	409
2	410
2	411
2	412
2	413
2	414
2	415
2	416
2	417
2	418
2	419
2	420
2	421
2	422
2	423
2	424
2	425
2	426
2	427
2	428
2	429
2	500
2	501
2	502
2	503
2	504
2	505
2	506
2	507
2	508
2	509
2	510
2	511
2	512
2	513
2	514
2	515
2	516
2	517
2	518
2	519
2	520
2	521
2	522
2	523
2	524
2	525
2	526
2	527
2	528
2	529
2	600
2	601
2	602
2	603
2	604
2	605
2	606
2	607
2	608
2	609
2	610
2	611
2	612
2	613
2	614
2	615
2	616
2	617
2	618
2	619
2	620
2	621
2	622
2	623
2	624
2	625
2	626
2	627
2	628
2	629
2	700
2	701
2	702
2	703
2	704
2	705
2	706
2	707
2	708
2	709
2	710
2	711
2	712
2	713
2	714
2	715
2	716
2	717
2	718
2	719
2	720
2	721
2	722
2	723
2	724
2	725
2	726
2	727
2	728
2	729
2	800
2	801
2	802
2	803
2	804
2	805
2	806
2	807
2	808
2	809
2	810
2	811
2	812
2	813
2	814
2	815
2	816
2	817
2	818
2	819
2	820
2	821
2	822
2	823
2	824
2	825
2	826
2	827
2	828
2	829
2	900
2	901
2	902
2	903
2	904
2	905
2	906
2	907
2	908
2	909
2	910
2	911
2	912
2	913
2	914
2	915
2	916
2	917
2	918
2	919
2	920
2	921
2	922
2	923
2	924
2	925
2	926
2	927
2	928
2	929
2	1000
2	1001
2	1002
2	1003
2	1004
2	1005
2	1006
2	1007
2	1008
2	1009
2	1010
2	1011
2	1012
2	1013
2	1014
2	1015
2	1016
2	1017
2	1018
2	1019
2	1020
2	1021
2	1022
2	1023
2	1024
2	1025
2	1026
2	1027
2	1028
2	1029
2	1100
2	1101
2	1102
2	1103
2	1104
2	1105
2	1106
2	1107
2	1108
2	1109
2	1110
2	1111
2	1112
2	1113
2	1114
2	1115
2	1116
2	1117
2	1118
2	1119
2	1120
2	1121
2	1122
2	1123
2	1124
2	1125
2	1126
2	1127
2	1128
2	1129
2	1200
2	1201
2	1202
2	1203
2	1204
2	1205
2	1206
2	1207
2	1208
2	1209
2	1210
2	1211
2	1212
2	1213
2	1214
2	1215
2	1216
2	1217
2	1218
2	1219
2	1220
2	1221
2	1222
2	1223
2	1224
2	1225
2	1226
2	1227
2	1228
2	1229
2	1300
2	1301
2	1302
2	1303
2	1304
2	1305
2	1306
2	1307
2	1308
2	1309
2	1310
2	1311
2	1312
2	1313
2	1314
2	1315
2	1316
2	1317
2	1318
2	1319
2	1320
2	1321
2	1322
2	1323
2	1324
2	1325
2	1326
2	1327
2	1328
2	1329
2	1400
2	1401
2	1402
2	1403
2	1404
2	1405
2	1406
2	1407
2	1408
2	1409
2	1410
2	1411
2	1412
2	1413
2	1414
2	1415
2	1416
2	1417
2	1418
2	1419
2	1420
2	1421
2	1422
2	1423
2	1424
2	1425
2	1426
2	1427
2	1428
2	1429
2	1500
2	1501
2	1502
2	1503
2	1504
2	1505
2	1506
2	1507
2	1508
2	1509
2	1510
2	1511
2	1512
2	1513
2	1514
2	1515
2	1516
2	1517
2	1518
2	1519
2	1520
2	1521
2	1522
2	1523
2	1524
2	1525
2	1526
2	1527
2	1528
2	1529
2	1600
2	1601
2	1602
2	1603
2	1604
2	1605
2	1606
2	1607
2	1608
2	1609
2	1610
2	1611
2	1612
2	1613
2	1614
2	1615
2	1616
2	1617
2	1618
2	1619
2	1620
2	1621
2	1622
2	1623
2	1624
2	1625
2	1626
2	1627
2	1628
2	1629
2	1700
2	1701
2	1702
2	1703
2	1704
2	1705
2	1706
2	1707
2	1708
2	1709
2	1710
2	1711
2	1712
2	1713
2	1714
2	1715
2	1716
2	1717
2	1718
2	1719
2	1720
2	1721
2	1722
2	1723
2	1724
2	1725
2	1726
2	1727
2	1728
2	1729
2	1800
2	1801
2	1802
2	1803
2	1804
2	1805
2	1806
2	1807
2	1808
2	1809
2	1810
2	1811
2	1812
2	1813
2	1814
2	1815
2	1816
2	1817
2	1818
2	1819
2	1820
2	1821
2	1822
2	1823
2	1824
2	1825
2	1826
2	1827
2	1828
2	1829
2	1900
2	1901
2	1902
2	1903
2	1904
2	1905
2	1906
2	1907
2	1908
2	1909
2	1910
2	1911
2	1912
2	1913
2	1914
2	1915
2	1916
2	1917
2	1918
2	1919
2	1920
2	1921
2	1922
2	1923
2	1924
2	1925
2	1926
2	1927
2	1928
2	1929
2	2000
2	2001
2	2002
2	2003
2	2004
2	2005
2	2006
2	2007
2	2008
2	2009
2	2010
2	2011
2	2012
2	2013
2	2014
2	2015
2	2016
2	2017
2	2018
2	2019
2	2020
2	2021
2	2022
2	2023
2	2024
2	2025
2	2026
2	2027
2	2028
2	2029
2	2100
2	2101
2	2102
2	2103
2	2104
2	2105
2	2106
2	2107
2	2108
2	2109
2	2110
2	2111
2	2112
2	2113
2	2114
2	2115
2	2116
2	2117
2	2118
2	2119
2	2120
2	2121
2	2122
2	2123
2	2124
2	2125
2	2126
2	2127
2	2128
2	2129
2	2200
2	2201
2	2202
2	2203
2	2204
2	2205
2	2206
2	2207
2	2208
2	2209
2	2210
2	2211
2	2212
2	2213
2	2214
2	2215
2	2216
2	2217
2	2218
2	2219
2	2220
2	2221
2	2222
2	2223
2	2224
2	2225
2	2226
2	2227
2	2228
2	2229
2	2300
2	2301
2	2302
2	2303
2	2304
2	2305
2	2306
2	2307
2	2308
2	2309
2	2310
2	2311
2	2312
2	2313
2	2314
2	2315
2	2316
2	2317
2	2318
2	2319
2	2320
2	2321
2	2322
2	2323
2	2324
2	2325
2	2326
2	2327
2	2328
2	2329
2	2400
2	2401
2	2402
2	2403
2	2404
2	2405
2	2406
2	2407
2	2408
2	2409
2	2410
2	2411
2	2412
2	2413
2	2414
2	2415
2	2416
2	2417
2	2418
2	2419
2	2420
2	2421
2	2422
2	2423
2	2424
2	2425
2	2426
2	2427
2	2428
2	2429
2	2500
2	2501
2	2502
2	2503
2	2504
2	2505
2	2506
2	2507
2	2508
2	2509
2	2510
2	2511
2	2512
2	2513
2	2514
2	2515
2	2516
2	2517
2	2518
2	2519
2	2520
2	2521
2	2522
2	2523
2	2524
2	2525
2	2526
2	2527
2	2528
2	2529
2	2600
2	2601
2	2602
2	2603
2	2604
2	2605
2	2606
2	2607
2	2608
2	2609
2	2610
2	2611
2	2612
2	2613
2	2614
2	2615
2	2616
2	2617
2	2618
2	2619
2	2620
2	2621
2	2622
2	2623
2	2624
2	2625
2	2626
2	2627
2	2628
2	2629
2	2700
2	2701
2	2702
2	2703
2	2704
2	2705
2	2706
2	2707
2	2708
2	2709
2	2710
2	2711
2	2712
2	2713
2	2714
2	2715
2	2716
2	2717
2	2718
2	2719
2	2720
2	2721
2	2722
2	2723
2	2724
2	2725
2	2726
2	2727
2	2728
2	2729
\.


--
-- Data for Name: mediafiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mediafiles (id, created_at, seconds) FROM stdin;
1	2019-12-22 18:46:57.637052	123
2	2019-12-22 18:50:20.302493	123
3	2019-12-22 18:53:41.525081	123
4	2019-12-22 18:53:41.525081	124
5	2019-12-22 19:02:07.347978	275
6	2019-12-22 19:02:07.347978	322
7	2019-12-22 19:02:07.347978	544
8	2019-12-22 19:02:07.347978	228
9	2019-12-22 19:02:07.347978	337
10	2019-12-22 19:02:07.347978	353
11	2019-12-22 19:02:07.347978	498
12	2019-12-22 19:02:07.347978	369
13	2019-12-22 19:02:07.347978	290
14	2019-12-22 19:02:07.347978	341
15	2019-12-22 19:02:07.347978	279
16	2019-12-22 19:02:07.347978	251
17	2019-12-22 19:02:07.347978	381
18	2019-12-22 19:02:07.347978	163
19	2019-12-22 19:02:07.347978	254
20	2019-12-22 19:02:07.347978	122
21	2019-12-22 19:02:07.347978	191
22	2019-12-22 19:02:07.347978	218
23	2019-12-22 19:02:07.347978	200
24	2019-12-22 19:02:07.347978	268
25	2019-12-22 19:02:07.347978	211
26	2019-12-22 19:02:07.347978	191
27	2019-12-22 19:02:07.347978	234
28	2019-12-22 19:02:07.347978	291
29	2019-12-22 19:02:07.347978	90
30	2019-12-22 19:02:07.347978	163
31	2019-12-22 19:02:07.347978	210
32	2019-12-22 19:02:07.347978	413
33	2019-12-22 19:02:07.347978	255
34	2019-12-22 19:02:07.347978	390
35	2019-12-22 19:02:07.347978	454
36	2019-12-22 19:02:07.347978	204
37	2019-12-22 19:02:07.347978	230
38	2019-12-22 19:02:07.347978	105
39	2019-12-22 19:02:07.347978	362
40	2019-12-22 19:02:07.347978	260
41	2019-12-22 19:02:07.347978	222
42	2019-12-22 19:02:07.347978	357
43	2019-12-22 19:02:07.347978	257
44	2019-12-22 19:02:07.347978	297
45	2019-12-22 19:02:07.347978	245
46	2019-12-22 19:02:07.347978	238
47	2019-12-22 19:02:07.347978	297
48	2019-12-22 19:02:07.347978	236
49	2019-12-22 19:02:07.347978	220
50	2019-12-22 19:02:07.347978	193
51	2019-12-22 19:02:07.347978	250
52	2019-12-22 19:02:07.347978	225
53	2019-12-22 19:02:07.347978	0
54	2019-12-22 19:02:07.347978	56
55	2019-12-22 19:02:07.347978	160
56	2019-12-22 19:02:07.347978	157
57	2019-12-22 19:02:07.347978	210
58	2019-12-22 19:02:07.347978	232
59	2019-12-22 19:02:07.347978	246
60	2019-12-22 19:02:07.347978	231
61	2019-12-22 19:02:07.347978	154
62	2019-12-22 19:02:07.347978	0
63	2019-12-22 19:02:07.347978	44
64	2019-12-22 19:02:07.347978	279
65	2019-12-22 19:02:07.347978	234
66	2019-12-22 19:02:07.347978	315
67	2019-12-22 19:02:07.347978	239
68	2019-12-22 19:02:07.347978	255
69	2019-12-22 19:02:07.347978	352
70	2019-12-22 19:02:07.347978	171
71	2019-12-22 19:02:07.347978	260
72	2019-12-22 19:02:07.347978	525
73	2019-12-22 19:02:07.347978	0
74	2019-12-22 19:02:07.347978	0
75	2019-12-22 19:02:07.347978	0
76	2019-12-22 19:02:07.347978	0
77	2019-12-22 19:02:07.347978	0
78	2019-12-22 19:02:07.347978	0
79	2019-12-22 19:02:07.347978	0
80	2019-12-22 19:02:07.347978	0
81	2019-12-22 19:02:07.347978	0
82	2019-12-22 19:02:07.347978	0
83	2019-12-22 19:02:07.347978	0
84	2019-12-22 19:02:07.347978	0
85	2019-12-22 19:02:07.347978	0
86	2019-12-22 19:02:07.347978	0
87	2019-12-22 19:02:07.347978	0
88	2019-12-22 19:02:07.347978	0
89	2019-12-22 19:02:07.347978	0
90	2019-12-22 19:02:07.347978	0
91	2019-12-22 19:02:07.347978	0
92	2019-12-22 19:02:07.347978	0
93	2019-12-22 19:02:07.347978	0
94	2019-12-22 19:02:07.347978	0
95	2019-12-22 19:02:07.347978	0
96	2019-12-22 19:02:07.347978	0
97	2019-12-22 19:02:07.347978	0
98	2019-12-22 19:02:07.347978	279
99	2019-12-22 19:02:07.347978	206
100	2019-12-22 19:02:07.347978	288
101	2019-12-22 19:02:07.347978	191
102	2019-12-22 19:02:07.347978	215
103	2019-12-22 19:02:07.347978	156
104	2019-12-22 19:02:07.347978	240
105	2019-12-22 19:02:07.347978	226
106	2019-12-22 19:02:07.347978	209
107	2019-12-22 19:02:07.347978	255
108	2019-12-22 19:02:07.347978	241
109	2019-12-22 19:02:07.347978	273
110	2019-12-22 19:02:07.347978	210
111	2019-12-22 19:02:07.347978	308
112	2019-12-22 19:02:07.347978	290
113	2019-12-22 19:02:07.347978	455
114	2019-12-22 19:02:07.347978	212
115	2019-12-22 19:02:07.347978	234
116	2019-12-22 19:02:07.347978	199
117	2019-12-22 19:02:07.347978	234
118	2019-12-22 19:02:07.347978	275
119	2019-12-22 19:02:07.347978	117
120	2019-12-22 19:02:07.347978	224
121	2019-12-22 19:02:07.347978	224
122	2019-12-22 19:02:07.347978	224
123	2019-12-22 19:02:07.347978	211
124	2019-12-22 19:02:07.347978	181
125	2019-12-22 19:02:07.347978	253
126	2019-12-22 19:02:07.347978	254
127	2019-12-22 19:02:07.347978	315
128	2019-12-22 19:02:07.347978	254
129	2019-12-22 19:02:07.347978	265
130	2019-12-22 19:02:07.347978	173
131	2019-12-22 19:02:07.347978	265
132	2019-12-22 19:02:07.347978	210
133	2019-12-22 19:02:07.347978	232
134	2019-12-22 19:02:07.347978	250
135	2019-12-22 19:02:07.347978	179
136	2019-12-22 19:02:07.347978	115
137	2019-12-22 19:02:07.347978	305
138	2019-12-22 19:02:07.347978	140
139	2019-12-22 19:02:07.347978	390
140	2019-12-22 19:02:07.347978	304
141	2019-12-22 19:02:07.347978	286
142	2019-12-22 19:02:07.347978	295
143	2019-12-22 19:02:07.347978	82
144	2019-12-22 19:02:07.347978	251
145	2019-12-22 19:02:07.347978	245
146	2019-12-22 19:02:07.347978	310
147	2019-12-22 19:02:07.347978	445
148	2019-12-22 19:02:07.347978	0
149	2019-12-22 19:02:07.347978	0
150	2019-12-22 19:02:07.347978	0
151	2019-12-22 19:02:07.347978	0
152	2019-12-22 19:02:07.347978	0
153	2019-12-22 19:02:07.347978	0
154	2019-12-22 19:02:07.347978	0
155	2019-12-22 19:02:07.347978	0
156	2019-12-22 19:02:07.347978	0
157	2019-12-22 19:02:07.347978	0
158	2019-12-22 19:02:07.347978	0
159	2019-12-22 19:02:07.347978	0
160	2019-12-22 19:02:07.347978	0
161	2019-12-22 19:02:07.347978	0
162	2019-12-22 19:02:07.347978	0
163	2019-12-22 19:02:07.347978	0
164	2019-12-22 19:02:07.347978	0
165	2019-12-22 19:02:07.347978	0
166	2019-12-22 19:02:07.347978	213
167	2019-12-22 19:02:07.347978	235
168	2019-12-22 19:02:07.347978	231
169	2019-12-22 19:02:07.347978	145
170	2019-12-22 19:02:07.347978	51
171	2019-12-22 19:02:07.347978	241
172	2019-12-22 19:02:07.347978	39
173	2019-12-22 19:02:07.347978	218
174	2019-12-22 19:02:07.347978	172
175	2019-12-22 19:02:07.347978	220
176	2019-12-22 19:02:07.347978	153
177	2019-12-22 19:02:07.347978	189
178	2019-12-22 19:02:07.347978	292
179	2019-12-22 19:02:07.347978	186
180	2019-12-22 19:02:07.347978	175
181	2019-12-22 19:02:07.347978	153
182	2019-12-22 19:02:07.347978	221
183	2019-12-22 19:02:07.347978	308
184	2019-12-22 19:02:07.347978	195
185	2019-12-22 19:02:07.347978	237
186	2019-12-22 19:02:07.347978	165
187	2019-12-22 19:02:07.347978	175
188	2019-12-22 19:02:07.347978	99
189	2019-12-22 19:02:07.347978	0
190	2019-12-22 19:02:07.347978	0
191	2019-12-22 19:02:07.347978	0
192	2019-12-22 19:02:07.347978	0
193	2019-12-22 19:02:07.347978	0
194	2019-12-22 19:02:07.347978	0
195	2019-12-22 19:02:07.347978	0
196	2019-12-22 19:02:07.347978	0
197	2019-12-22 19:02:07.347978	0
198	2019-12-22 19:02:07.347978	0
199	2019-12-22 19:02:07.347978	0
200	2019-12-22 19:02:07.347978	0
201	2019-12-22 19:02:07.347978	0
202	2019-12-22 19:02:07.347978	0
203	2019-12-22 19:02:07.347978	0
204	2019-12-22 19:02:07.347978	0
205	2019-12-22 19:02:07.347978	0
206	2019-12-22 19:02:07.347978	0
207	2019-12-22 19:02:07.347978	0
208	2019-12-22 19:02:07.347978	0
209	2019-12-22 19:02:07.347978	0
210	2019-12-22 19:02:07.347978	0
211	2019-12-22 19:02:07.347978	0
212	2019-12-22 19:02:07.347978	0
213	2019-12-22 19:02:07.347978	0
214	2019-12-22 19:02:07.347978	0
215	2019-12-22 19:02:07.347978	0
216	2019-12-22 19:02:07.347978	0
217	2019-12-22 19:02:07.347978	0
218	2019-12-22 19:02:07.347978	0
219	2019-12-22 19:02:07.347978	0
220	2019-12-22 19:02:07.347978	0
221	2019-12-22 19:02:07.347978	0
222	2019-12-22 19:02:07.347978	0
223	2019-12-22 19:02:07.347978	0
224	2019-12-22 19:02:07.347978	0
225	2019-12-22 19:02:07.347978	0
226	2019-12-22 19:02:07.347978	0
227	2019-12-22 19:02:07.347978	0
228	2019-12-22 19:02:07.347978	0
229	2019-12-22 19:02:07.347978	0
230	2019-12-22 19:02:07.347978	0
231	2019-12-22 19:02:07.347978	315
232	2019-12-22 19:02:07.347978	252
233	2019-12-22 19:02:07.347978	344
234	2019-12-22 19:02:07.347978	160
235	2019-12-22 19:02:07.347978	250
236	2019-12-22 19:02:07.347978	309
237	2019-12-22 19:02:07.347978	243
238	2019-12-22 19:02:07.347978	272
239	2019-12-22 19:02:07.347978	173
240	2019-12-22 19:02:07.347978	432
241	2019-12-22 19:02:07.347978	284
242	2019-12-22 19:02:07.347978	295
243	2019-12-22 19:02:07.347978	476
244	2019-12-22 19:02:07.347978	179
245	2019-12-22 19:02:07.347978	284
246	2019-12-22 19:02:07.347978	198
247	2019-12-22 19:02:07.347978	259
248	2019-12-22 19:02:07.347978	252
249	2019-12-22 19:02:07.347978	0
250	2019-12-22 19:02:07.347978	0
251	2019-12-22 19:02:07.347978	0
252	2019-12-22 19:02:07.347978	0
253	2019-12-22 19:02:07.347978	0
254	2019-12-22 19:02:07.347978	0
255	2019-12-22 19:02:07.347978	0
256	2019-12-22 19:02:07.347978	0
257	2019-12-22 19:02:07.347978	0
258	2019-12-22 19:02:07.347978	0
259	2019-12-22 19:02:07.347978	0
260	2019-12-22 19:02:07.347978	0
261	2019-12-22 19:02:07.347978	0
262	2019-12-22 19:02:07.347978	0
263	2019-12-22 19:02:07.347978	0
264	2019-12-22 19:02:07.347978	0
265	2019-12-22 19:02:07.347978	0
266	2019-12-22 19:02:07.347978	0
267	2019-12-22 19:02:07.347978	193
268	2019-12-22 19:02:07.347978	221
269	2019-12-22 19:02:07.347978	224
270	2019-12-22 19:02:07.347978	251
271	2019-12-22 19:02:07.347978	177
272	2019-12-22 19:02:07.347978	197
273	2019-12-22 19:02:07.347978	205
274	2019-12-22 19:02:07.347978	225
275	2019-12-22 19:02:07.347978	210
276	2019-12-22 19:02:07.347978	207
277	2019-12-22 19:02:07.347978	195
278	2019-12-22 19:02:07.347978	193
279	2019-12-22 19:02:07.347978	221
280	2019-12-22 19:02:07.347978	224
281	2019-12-22 19:02:07.347978	251
282	2019-12-22 19:02:07.347978	177
283	2019-12-22 19:02:07.347978	197
284	2019-12-22 19:02:07.347978	205
285	2019-12-22 19:02:07.347978	225
286	2019-12-22 19:02:07.347978	210
287	2019-12-22 19:02:07.347978	207
288	2019-12-22 19:02:07.347978	195
289	2019-12-22 19:02:07.347978	354
290	2019-12-22 19:02:07.347978	328
291	2019-12-22 19:02:07.347978	282
292	2019-12-22 19:02:07.347978	261
293	2019-12-22 19:02:07.347978	207
294	2019-12-22 19:02:07.347978	167
295	2019-12-22 19:02:07.347978	283
296	2019-12-22 19:02:07.347978	422
297	2019-12-22 19:02:07.347978	83
298	2019-12-22 19:02:07.347978	339
299	2019-12-22 19:02:07.347978	215
300	2019-12-22 19:02:07.347978	465
301	2019-12-22 19:02:07.347978	426
302	2019-12-22 19:02:07.347978	855
303	2019-12-22 19:02:07.347978	282
304	2019-12-22 19:02:07.347978	214
305	2019-12-22 19:02:07.347978	280
306	2019-12-22 19:02:07.347978	250
307	2019-12-22 19:02:07.347978	178
308	2019-12-22 19:02:07.347978	202
309	2019-12-22 19:02:07.347978	167
310	2019-12-22 19:02:07.347978	160
311	2019-12-22 19:02:07.347978	193
312	2019-12-22 19:02:07.347978	205
313	2019-12-22 19:02:07.347978	178
314	2019-12-22 19:02:07.347978	280
315	2019-12-22 19:02:07.347978	357
316	2019-12-22 19:02:07.347978	292
317	2019-12-22 19:02:07.347978	62
318	2019-12-22 19:02:07.347978	299
319	2019-12-22 19:02:07.347978	378
320	2019-12-22 19:02:07.347978	398
321	2019-12-22 19:02:07.347978	352
322	2019-12-22 19:02:07.347978	548
323	2019-12-22 19:02:07.347978	327
324	2019-12-22 19:02:07.347978	469
325	2019-12-22 19:02:07.347978	256
326	2019-12-22 19:02:07.347978	98
327	2019-12-22 19:02:07.347978	239
328	2019-12-22 19:02:07.347978	305
329	2019-12-22 19:02:07.347978	221
330	2019-12-22 19:02:07.347978	196
331	2019-12-22 19:02:07.347978	278
332	2019-12-22 19:02:07.347978	281
333	2019-12-22 19:02:07.347978	194
334	2019-12-22 19:02:07.347978	146
335	2019-12-22 19:02:07.347978	306
336	2019-12-22 19:02:07.347978	158
337	2019-12-22 19:02:07.347978	283
338	2019-12-22 19:02:07.347978	1319
339	2019-12-22 19:02:07.347978	1267
340	2019-12-22 19:02:07.347978	1272
341	2019-12-22 19:02:07.347978	0
342	2019-12-22 19:02:07.347978	0
343	2019-12-22 19:02:07.347978	0
344	2019-12-22 19:02:07.347978	0
345	2019-12-22 19:02:07.347978	0
346	2019-12-22 19:02:07.347978	0
347	2019-12-22 19:02:07.347978	0
348	2019-12-22 19:02:07.347978	0
349	2019-12-22 19:02:07.347978	0
350	2019-12-22 19:02:07.347978	0
351	2019-12-22 19:02:07.347978	0
352	2019-12-22 19:02:07.347978	0
353	2019-12-22 19:02:07.347978	0
354	2019-12-22 19:02:07.347978	0
355	2019-12-22 19:02:07.347978	0
356	2019-12-22 19:02:07.347978	0
357	2019-12-22 19:02:07.347978	0
358	2019-12-22 19:02:07.347978	0
359	2019-12-22 19:02:07.347978	0
360	2019-12-22 19:02:07.347978	0
361	2019-12-22 19:02:07.347978	0
362	2019-12-22 19:02:07.347978	0
363	2019-12-22 19:02:07.347978	247
364	2019-12-22 19:02:07.347978	219
365	2019-12-22 19:02:07.347978	176
366	2019-12-22 19:02:07.347978	175
367	2019-12-22 19:02:07.347978	250
368	2019-12-22 19:02:07.347978	214
369	2019-12-22 19:02:07.347978	179
370	2019-12-22 19:02:07.347978	225
371	2019-12-22 19:02:07.347978	225
372	2019-12-22 19:02:07.347978	165
373	2019-12-22 19:02:07.347978	185
374	2019-12-22 19:02:07.347978	248
375	2019-12-22 19:02:07.347978	274
376	2019-12-22 19:02:07.347978	219
377	2019-12-22 19:02:07.347978	130
378	2019-12-22 19:02:07.347978	274
379	2019-12-22 19:02:07.347978	275
380	2019-12-22 19:02:07.347978	302
381	2019-12-22 19:02:07.347978	312
382	2019-12-22 19:02:07.347978	177
383	2019-12-22 19:02:07.347978	235
384	2019-12-22 19:02:07.347978	231
385	2019-12-22 19:02:07.347978	147
386	2019-12-22 19:02:07.347978	185
387	2019-12-22 19:02:07.347978	282
388	2019-12-22 19:02:07.347978	307
389	2019-12-22 19:02:07.347978	198
390	2019-12-22 19:02:07.347978	250
391	2019-12-22 19:02:07.347978	219
392	2019-12-22 19:02:07.347978	191
393	2019-12-22 19:02:07.347978	227
394	2019-12-22 19:02:07.347978	219
395	2019-12-22 19:02:07.347978	201
396	2019-12-22 19:02:07.347978	238
397	2019-12-22 19:02:07.347978	322
398	2019-12-22 19:02:07.347978	329
399	2019-12-22 19:02:07.347978	186
400	2019-12-22 19:02:07.347978	116
401	2019-12-22 19:02:07.347978	220
402	2019-12-22 19:02:07.347978	400
403	2019-12-22 19:02:07.347978	597
404	2019-12-22 19:02:07.347978	292
405	2019-12-22 19:02:07.347978	382
406	2019-12-22 19:02:07.347978	280
407	2019-12-22 19:02:07.347978	291
408	2019-12-22 19:02:07.347978	284
409	2019-12-22 19:02:07.347978	347
410	2019-12-22 19:02:07.347978	212
411	2019-12-22 19:02:07.347978	142
412	2019-12-22 19:02:07.347978	299
413	2019-12-22 19:02:07.347978	204
414	2019-12-22 19:02:07.347978	211
415	2019-12-22 19:02:07.347978	218
416	2019-12-22 19:02:07.347978	318
417	2019-12-22 19:02:07.347978	227
418	2019-12-22 19:02:07.347978	262
419	2019-12-22 19:02:07.347978	208
420	2019-12-22 19:02:07.347978	285
421	2019-12-22 19:02:07.347978	115
422	2019-12-22 19:02:07.347978	118
423	2019-12-22 19:02:07.347978	131
424	2019-12-22 19:02:07.347978	68
425	2019-12-22 19:02:07.347978	155
426	2019-12-22 19:02:07.347978	234
427	2019-12-22 19:02:07.347978	81
428	2019-12-22 19:02:07.347978	171
429	2019-12-22 19:02:07.347978	93
430	2019-12-22 19:02:07.347978	52
431	2019-12-22 19:02:07.347978	161
432	2019-12-22 19:02:07.347978	20
433	2019-12-22 19:02:07.347978	156
434	2019-12-22 19:02:07.347978	90
435	2019-12-22 19:02:07.347978	145
436	2019-12-22 19:02:07.347978	81
437	2019-12-22 19:02:07.347978	83
438	2019-12-22 19:02:07.347978	29
439	2019-12-22 19:02:07.347978	115
440	2019-12-22 19:02:07.347978	117
441	2019-12-22 19:02:07.347978	52
442	2019-12-22 19:02:07.347978	130
443	2019-12-22 19:02:07.347978	136
444	2019-12-22 19:02:07.347978	240
445	2019-12-22 19:02:07.347978	250
446	2019-12-22 19:02:07.347978	265
447	2019-12-22 19:02:07.347978	301
448	2019-12-22 19:02:07.347978	219
449	2019-12-22 19:02:07.347978	228
450	2019-12-22 19:02:07.347978	315
451	2019-12-22 19:02:07.347978	253
452	2019-12-22 19:02:07.347978	200
453	2019-12-22 19:02:07.347978	328
454	2019-12-22 19:02:07.347978	201
455	2019-12-22 19:02:07.347978	300
456	2019-12-22 19:02:07.347978	253
457	2019-12-22 19:02:07.347978	218
458	2019-12-22 19:02:07.347978	183
459	2019-12-22 19:02:07.347978	256
460	2019-12-22 19:02:07.347978	176
461	2019-12-22 19:02:07.347978	142
462	2019-12-22 19:02:07.347978	223
463	2019-12-22 19:02:07.347978	155
464	2019-12-22 19:02:07.347978	210
465	2019-12-22 19:02:07.347978	192
466	2019-12-22 19:02:07.347978	223
467	2019-12-22 19:02:07.347978	246
468	2019-12-22 19:02:07.347978	298
469	2019-12-22 19:02:07.347978	241
470	2019-12-22 19:02:07.347978	232
471	2019-12-22 19:02:07.347978	245
472	2019-12-22 19:02:07.347978	233
473	2019-12-22 19:02:07.347978	318
474	2019-12-22 19:02:07.347978	263
475	2019-12-22 19:02:07.347978	292
476	2019-12-22 19:02:07.347978	256
477	2019-12-22 19:02:07.347978	531
478	2019-12-22 19:02:07.347978	299
479	2019-12-22 19:02:07.347978	361
480	2019-12-22 19:02:07.347978	431
481	2019-12-22 19:02:07.347978	411
482	2019-12-22 19:02:07.347978	354
483	2019-12-22 19:02:07.347978	187
484	2019-12-22 19:02:07.347978	348
485	2019-12-22 19:02:07.347978	249
486	2019-12-22 19:02:07.347978	461
487	2019-12-22 19:02:07.347978	1759
488	2019-12-22 19:02:07.347978	250
489	2019-12-22 19:02:07.347978	177
490	2019-12-22 19:02:07.347978	273
491	2019-12-22 19:02:07.347978	365
492	2019-12-22 19:02:07.347978	286
493	2019-12-22 19:02:07.347978	408
494	2019-12-22 19:02:07.347978	1733
495	2019-12-22 19:02:07.347978	288
496	2019-12-22 19:02:07.347978	216
497	2019-12-22 19:02:07.347978	252
498	2019-12-22 19:02:07.347978	350
499	2019-12-22 19:02:07.347978	257
500	2019-12-22 19:02:07.347978	308
501	2019-12-22 19:02:07.347978	62
502	2019-12-22 19:02:07.347978	237
503	2019-12-22 19:02:07.347978	242
504	2019-12-22 19:02:07.347978	255
505	2019-12-22 19:02:07.347978	318
506	2019-12-22 19:02:07.347978	229
507	2019-12-22 19:02:07.347978	130
508	2019-12-22 19:02:07.347978	290
509	2019-12-22 19:02:07.347978	328
510	2019-12-22 19:02:07.347978	249
511	2019-12-22 19:02:07.347978	280
512	2019-12-22 19:02:07.347978	362
513	2019-12-22 19:02:07.347978	218
514	2019-12-22 19:02:07.347978	312
515	2019-12-22 19:02:07.347978	284
516	2019-12-22 19:02:07.347978	244
517	2019-12-22 19:02:07.347978	184
518	2019-12-22 19:02:07.347978	216
519	2019-12-22 19:02:07.347978	267
520	2019-12-22 19:02:07.347978	226
521	2019-12-22 19:02:07.347978	218
522	2019-12-22 19:02:07.347978	0
523	2019-12-22 19:02:07.347978	0
524	2019-12-22 19:02:07.347978	0
525	2019-12-22 19:02:07.347978	0
526	2019-12-22 19:02:07.347978	0
527	2019-12-22 19:02:07.347978	0
528	2019-12-22 19:02:07.347978	0
529	2019-12-22 19:02:07.347978	0
530	2019-12-22 19:02:07.347978	0
531	2019-12-22 19:02:07.347978	0
532	2019-12-22 19:02:07.347978	0
533	2019-12-22 19:02:07.347978	0
534	2019-12-22 19:02:07.347978	301
535	2019-12-22 19:02:07.347978	250
536	2019-12-22 19:02:07.347978	226
537	2019-12-22 19:02:07.347978	286
538	2019-12-22 19:02:07.347978	308
539	2019-12-22 19:02:07.347978	222
540	2019-12-22 19:02:07.347978	226
541	2019-12-22 19:02:07.347978	219
542	2019-12-22 19:02:07.347978	196
543	2019-12-22 19:02:07.347978	0
544	2019-12-22 19:02:07.347978	0
545	2019-12-22 19:02:07.347978	0
546	2019-12-22 19:02:07.347978	0
547	2019-12-22 19:02:07.347978	0
548	2019-12-22 19:02:07.347978	0
549	2019-12-22 19:02:07.347978	0
550	2019-12-22 19:02:07.347978	0
551	2019-12-22 19:02:07.347978	0
552	2019-12-22 19:02:07.347978	0
553	2019-12-22 19:02:07.347978	0
554	2019-12-22 19:02:07.347978	0
555	2019-12-22 19:02:07.347978	0
556	2019-12-22 19:02:07.347978	0
557	2019-12-22 19:02:07.347978	0
558	2019-12-22 19:02:07.347978	0
559	2019-12-22 19:02:07.347978	0
560	2019-12-22 19:02:07.347978	201
561	2019-12-22 19:02:07.347978	239
562	2019-12-22 19:02:07.347978	258
563	2019-12-22 19:02:07.347978	288
564	2019-12-22 19:02:07.347978	341
565	2019-12-22 19:02:07.347978	44
566	2019-12-22 19:02:07.347978	243
567	2019-12-22 19:02:07.347978	329
568	2019-12-22 19:02:07.347978	291
569	2019-12-22 19:02:07.347978	220
570	2019-12-22 19:02:07.347978	303
571	2019-12-22 19:02:07.347978	39
572	2019-12-22 19:02:07.347978	447
573	2019-12-22 19:02:07.347978	163
574	2019-12-22 19:02:07.347978	165
575	2019-12-22 19:02:07.347978	117
576	2019-12-22 19:02:07.347978	167
577	2019-12-22 19:02:07.347978	192
578	2019-12-22 19:02:07.347978	217
579	2019-12-22 19:02:07.347978	233
580	2019-12-22 19:02:07.347978	144
581	2019-12-22 19:02:07.347978	96
582	2019-12-22 19:02:07.347978	90
583	2019-12-22 19:02:07.347978	135
584	2019-12-22 19:02:07.347978	200
585	2019-12-22 19:02:07.347978	160
586	2019-12-22 19:02:07.347978	108
587	2019-12-22 19:02:07.347978	150
588	2019-12-22 19:02:07.347978	367
589	2019-12-22 19:02:07.347978	0
590	2019-12-22 19:02:07.347978	284
591	2019-12-22 19:02:07.347978	383
592	2019-12-22 19:02:07.347978	267
593	2019-12-22 19:02:07.347978	0
594	2019-12-22 19:02:07.347978	264
595	2019-12-22 19:02:07.347978	299
596	2019-12-22 19:02:07.347978	261
597	2019-12-22 19:02:07.347978	0
598	2019-12-22 19:02:07.347978	117
599	2019-12-22 19:02:07.347978	230
600	2019-12-22 19:02:07.347978	285
601	2019-12-22 19:02:07.347978	228
602	2019-12-22 19:02:07.347978	0
603	2019-12-22 19:02:07.347978	259
604	2019-12-22 19:02:07.347978	324
605	2019-12-22 19:02:07.347978	320
606	2019-12-22 19:02:07.347978	370
607	2019-12-22 19:02:07.347978	258
608	2019-12-22 19:02:07.347978	171
609	2019-12-22 19:02:07.347978	226
610	2019-12-22 19:02:07.347978	242
611	2019-12-22 19:02:07.347978	286
612	2019-12-22 19:02:07.347978	252
613	2019-12-22 19:02:07.347978	164
614	2019-12-22 19:02:07.347978	170
615	2019-12-22 19:02:07.347978	241
616	2019-12-22 19:02:07.347978	166
617	2019-12-22 19:02:07.347978	277
618	2019-12-22 19:02:07.347978	244
619	2019-12-22 19:02:07.347978	725
620	2019-12-22 19:02:07.347978	328
621	2019-12-22 19:02:07.347978	204
622	2019-12-22 19:02:07.347978	216
623	2019-12-22 19:02:07.347978	180
624	2019-12-22 19:02:07.347978	167
625	2019-12-22 19:02:07.347978	150
626	2019-12-22 19:02:07.347978	242
627	2019-12-22 19:02:07.347978	98
628	2019-12-22 19:02:07.347978	192
629	2019-12-22 19:02:07.347978	177
630	2019-12-22 19:02:07.347978	142
631	2019-12-22 19:02:07.347978	138
632	2019-12-22 19:02:07.347978	120
633	2019-12-22 19:02:07.347978	135
634	2019-12-22 19:02:07.347978	83
635	2019-12-22 19:02:07.347978	279
636	2019-12-22 19:02:07.347978	126
637	2019-12-22 19:02:07.347978	132
638	2019-12-22 19:02:07.347978	160
639	2019-12-22 19:02:07.347978	128
640	2019-12-22 19:02:07.347978	138
641	2019-12-22 19:02:07.347978	80
642	2019-12-22 19:02:07.347978	194
643	2019-12-22 19:02:07.347978	83
644	2019-12-22 19:02:07.347978	204
645	2019-12-22 19:02:07.347978	201
646	2019-12-22 19:02:07.347978	208
647	2019-12-22 19:02:07.347978	221
648	2019-12-22 19:02:07.347978	182
649	2019-12-22 19:02:07.347978	201
650	2019-12-22 19:02:07.347978	208
651	2019-12-22 19:02:07.347978	214
652	2019-12-22 19:02:07.347978	219
653	2019-12-22 19:02:07.347978	207
654	2019-12-22 19:02:07.347978	398
655	2019-12-22 19:02:07.347978	239
656	2019-12-22 19:02:07.347978	424
657	2019-12-22 19:02:07.347978	247
658	2019-12-22 19:02:07.347978	286
659	2019-12-22 19:02:07.347978	322
660	2019-12-22 19:02:07.347978	417
661	2019-12-22 19:02:07.347978	276
662	2019-12-22 19:02:07.347978	216
663	2019-12-22 19:02:07.347978	416
664	2019-12-22 19:02:07.347978	536
665	2019-12-22 19:02:07.347978	572
666	2019-12-22 19:02:07.347978	327
667	2019-12-22 19:02:07.347978	694
668	2019-12-22 19:02:07.347978	572
669	2019-12-22 19:02:07.347978	228
670	2019-12-22 19:02:07.347978	258
671	2019-12-22 19:02:07.347978	251
672	2019-12-22 19:02:07.347978	289
673	2019-12-22 19:02:07.347978	205
674	2019-12-22 19:02:07.347978	269
675	2019-12-22 19:02:07.347978	291
676	2019-12-22 19:02:07.347978	282
677	2019-12-22 19:02:07.347978	229
678	2019-12-22 19:02:07.347978	228
679	2019-12-22 19:02:07.347978	176
680	2019-12-22 19:02:07.347978	287
681	2019-12-22 19:02:07.347978	193
682	2019-12-22 19:02:07.347978	395
683	2019-12-22 19:02:07.347978	92
684	2019-12-22 19:02:07.347978	222
685	2019-12-22 19:02:07.347978	138
686	2019-12-22 19:02:07.347978	256
687	2019-12-22 19:02:07.347978	169
688	2019-12-22 19:02:07.347978	245
689	2019-12-22 19:02:07.347978	268
690	2019-12-22 19:02:07.347978	119
691	2019-12-22 19:02:07.347978	232
692	2019-12-22 19:02:07.347978	136
693	2019-12-22 19:02:07.347978	339
694	2019-12-22 19:02:07.347978	247
695	2019-12-22 19:02:07.347978	210
696	2019-12-22 19:02:07.347978	288
697	2019-12-22 19:02:07.347978	212
698	2019-12-22 19:02:07.347978	312
699	2019-12-22 19:02:07.347978	221
700	2019-12-22 19:02:07.347978	289
701	2019-12-22 19:02:07.347978	282
702	2019-12-22 19:02:07.347978	335
703	2019-12-22 19:02:07.347978	247
704	2019-12-22 19:02:07.347978	310
705	2019-12-22 19:02:07.347978	380
706	2019-12-22 19:02:07.347978	244
707	2019-12-22 19:02:07.347978	178
708	2019-12-22 19:02:07.347978	120
709	2019-12-22 19:02:07.347978	166
710	2019-12-22 19:02:07.347978	205
711	2019-12-22 19:02:07.347978	297
712	2019-12-22 19:02:07.347978	225
713	2019-12-22 19:02:07.347978	271
714	2019-12-22 19:02:07.347978	203
715	2019-12-22 19:02:07.347978	175
716	2019-12-22 19:02:07.347978	166
717	2019-12-22 19:02:07.347978	134
718	2019-12-22 19:02:07.347978	414
719	2019-12-22 19:02:07.347978	202
720	2019-12-22 19:02:07.347978	162
721	2019-12-22 19:02:07.347978	290
722	2019-12-22 19:02:07.347978	188
723	2019-12-22 19:02:07.347978	189
724	2019-12-22 19:02:07.347978	217
725	2019-12-22 19:02:07.347978	178
726	2019-12-22 19:02:07.347978	196
727	2019-12-22 19:02:07.347978	184
728	2019-12-22 19:02:07.347978	256
729	2019-12-22 19:02:07.347978	179
730	2019-12-22 19:02:07.347978	168
731	2019-12-22 19:02:07.347978	241
732	2019-12-22 19:02:07.347978	224
733	2019-12-22 19:02:07.347978	220
734	2019-12-22 19:02:07.347978	145
735	2019-12-22 19:02:07.347978	210
736	2019-12-22 19:02:07.347978	150
737	2019-12-22 19:02:07.347978	150
738	2019-12-22 19:02:07.347978	195
739	2019-12-22 19:02:07.347978	410
740	2019-12-22 19:02:07.347978	210
741	2019-12-22 19:02:07.347978	138
742	2019-12-22 19:02:07.347978	169
743	2019-12-22 19:02:07.347978	133
744	2019-12-22 19:02:07.347978	695
745	2019-12-22 19:02:07.347978	210
746	2019-12-22 19:02:07.347978	255
747	2019-12-22 19:02:07.347978	150
748	2019-12-22 19:02:07.347978	190
749	2019-12-22 19:02:07.347978	240
750	2019-12-22 19:02:07.347978	152
751	2019-12-22 19:02:07.347978	183
752	2019-12-22 19:02:07.347978	220
753	2019-12-22 19:02:07.347978	140
754	2019-12-22 19:02:07.347978	165
755	2019-12-22 19:02:07.347978	200
756	2019-12-22 19:02:07.347978	213
757	2019-12-22 19:02:07.347978	242
758	2019-12-22 19:02:07.347978	184
759	2019-12-22 19:02:07.347978	162
760	2019-12-22 19:02:07.347978	286
761	2019-12-22 19:02:07.347978	199
762	2019-12-22 19:02:07.347978	257
763	2019-12-22 19:02:07.347978	190
764	2019-12-22 19:02:07.347978	156
765	2019-12-22 19:02:07.347978	206
766	2019-12-22 19:02:07.347978	299
767	2019-12-22 19:02:07.347978	365
768	2019-12-22 19:02:07.347978	182
769	2019-12-22 19:02:07.347978	214
770	2019-12-22 19:02:07.347978	280
771	2019-12-22 19:02:07.347978	233
772	2019-12-22 19:02:07.347978	244
773	2019-12-22 19:02:07.347978	327
774	2019-12-22 19:02:07.347978	506
775	2019-12-22 19:02:07.347978	233
776	2019-12-22 19:02:07.347978	262
777	2019-12-22 19:02:07.347978	232
778	2019-12-22 19:02:07.347978	337
779	2019-12-22 19:02:07.347978	188
780	2019-12-22 19:02:07.347978	226
781	2019-12-22 19:02:07.347978	165
782	2019-12-22 19:02:07.347978	299
783	2019-12-22 19:02:07.347978	250
784	2019-12-22 19:02:07.347978	93
785	2019-12-22 19:02:07.347978	317
786	2019-12-22 19:02:07.347978	288
787	2019-12-22 19:02:07.347978	631
788	2019-12-22 19:02:07.347978	304
789	2019-12-22 19:02:07.347978	269
790	2019-12-22 19:02:07.347978	192
791	2019-12-22 19:02:07.347978	360
792	2019-12-22 19:02:07.347978	59
793	2019-12-22 19:02:07.347978	441
794	2019-12-22 19:02:07.347978	393
795	2019-12-22 19:02:07.347978	259
796	2019-12-22 19:02:07.347978	362
797	2019-12-22 19:02:07.347978	322
798	2019-12-22 19:02:07.347978	235
799	2019-12-22 19:02:07.347978	161
800	2019-12-22 19:02:07.347978	177
801	2019-12-22 19:02:07.347978	94
802	2019-12-22 19:02:07.347978	238
803	2019-12-22 19:02:07.347978	139
804	2019-12-22 19:02:07.347978	241
805	2019-12-22 19:02:07.347978	239
806	2019-12-22 19:02:07.347978	188
807	2019-12-22 19:02:07.347978	212
808	2019-12-22 19:02:07.347978	174
809	2019-12-22 19:02:07.347978	153
810	2019-12-22 19:02:07.347978	242
811	2019-12-22 19:02:07.347978	200
812	2019-12-22 19:02:07.347978	0
813	2019-12-22 19:02:07.347978	0
814	2019-12-22 19:02:07.347978	0
815	2019-12-22 19:02:07.347978	0
816	2019-12-22 19:02:07.347978	0
817	2019-12-22 19:02:07.347978	208
818	2019-12-22 19:02:07.347978	218
819	2019-12-22 19:02:07.347978	220
820	2019-12-22 19:02:07.347978	264
821	2019-12-22 19:02:07.347978	254
822	2019-12-22 19:02:07.347978	260
823	2019-12-22 19:02:07.347978	247
824	2019-12-22 19:02:07.347978	173
825	2019-12-22 19:02:07.347978	290
826	2019-12-22 19:02:07.347978	256
827	2019-12-22 19:02:07.347978	283
828	2019-12-22 19:02:07.347978	248
829	2019-12-22 19:02:07.347978	178
830	2019-12-22 19:02:07.347978	260
831	2019-12-22 19:02:07.347978	223
832	2019-12-22 19:02:07.347978	172
833	2019-12-22 19:02:07.347978	354
834	2019-12-22 19:02:07.347978	222
835	2019-12-22 19:02:07.347978	190
836	2019-12-22 19:02:07.347978	285
837	2019-12-22 19:02:07.347978	167
838	2019-12-22 19:02:07.347978	212
839	2019-12-22 19:02:07.347978	191
840	2019-12-22 19:02:07.347978	217
841	2019-12-22 19:02:07.347978	254
842	2019-12-22 19:02:07.347978	277
843	2019-12-22 19:02:07.347978	260
844	2019-12-22 19:02:07.347978	220
845	2019-12-22 19:02:07.347978	172
846	2019-12-22 19:02:07.347978	196
847	2019-12-22 19:02:07.347978	224
848	2019-12-22 19:02:07.347978	241
849	2019-12-22 19:02:07.347978	218
850	2019-12-22 19:02:07.347978	206
851	2019-12-22 19:02:07.347978	175
852	2019-12-22 19:02:07.347978	263
853	2019-12-22 19:02:07.347978	307
854	2019-12-22 19:02:07.347978	0
855	2019-12-22 19:02:07.347978	0
856	2019-12-22 19:02:07.347978	0
857	2019-12-22 19:02:07.347978	0
858	2019-12-22 19:02:07.347978	0
859	2019-12-22 19:02:07.347978	0
860	2019-12-22 19:02:07.347978	0
861	2019-12-22 19:02:07.347978	0
862	2019-12-22 19:02:07.347978	0
863	2019-12-22 19:02:07.347978	0
864	2019-12-22 19:02:07.347978	168
865	2019-12-22 19:02:07.347978	180
866	2019-12-22 19:02:07.347978	136
867	2019-12-22 19:02:07.347978	230
868	2019-12-22 19:02:07.347978	153
869	2019-12-22 19:02:07.347978	275
870	2019-12-22 19:02:07.347978	204
871	2019-12-22 19:02:07.347978	245
872	2019-12-22 19:02:07.347978	177
873	2019-12-22 19:02:07.347978	187
874	2019-12-22 19:02:07.347978	237
875	2019-12-22 19:02:07.347978	220
876	2019-12-22 19:02:07.347978	235
877	2019-12-22 19:02:07.347978	206
878	2019-12-22 19:02:07.347978	230
879	2019-12-22 19:02:07.347978	143
880	2019-12-22 19:02:07.347978	223
881	2019-12-22 19:02:07.347978	268
882	2019-12-22 19:02:07.347978	105
883	2019-12-22 19:02:07.347978	194
884	2019-12-22 19:02:07.347978	202
885	2019-12-22 19:02:07.347978	220
886	2019-12-22 19:02:07.347978	384
887	2019-12-22 19:02:07.347978	281
888	2019-12-22 19:02:07.347978	224
889	2019-12-22 19:02:07.347978	367
890	2019-12-22 19:02:07.347978	172
891	2019-12-22 19:02:07.347978	266
892	2019-12-22 19:02:07.347978	345
893	2019-12-22 19:02:07.347978	306
894	2019-12-22 19:02:07.347978	303
895	2019-12-22 19:02:07.347978	283
896	2019-12-22 19:02:07.347978	321
897	2019-12-22 19:02:07.347978	207
898	2019-12-22 19:02:07.347978	298
899	2019-12-22 19:02:07.347978	223
900	2019-12-22 19:02:07.347978	208
901	2019-12-22 19:02:07.347978	103
902	2019-12-22 19:02:07.347978	237
903	2019-12-22 19:02:07.347978	193
904	2019-12-22 19:02:07.347978	230
905	2019-12-22 19:02:07.347978	226
906	2019-12-22 19:02:07.347978	344
907	2019-12-22 19:02:07.347978	204
908	2019-12-22 19:02:07.347978	238
909	2019-12-22 19:02:07.347978	600
910	2019-12-22 19:02:07.347978	242
911	2019-12-22 19:02:07.347978	124
912	2019-12-22 19:02:07.347978	307
913	2019-12-22 19:02:07.347978	103
914	2019-12-22 19:02:07.347978	182
915	2019-12-22 19:02:07.347978	170
916	2019-12-22 19:02:07.347978	188
917	2019-12-22 19:02:07.347978	150
918	2019-12-22 19:02:07.347978	292
919	2019-12-22 19:02:07.347978	214
920	2019-12-22 19:02:07.347978	196
921	2019-12-22 19:02:07.347978	186
922	2019-12-22 19:02:07.347978	76
923	2019-12-22 19:02:07.347978	175
924	2019-12-22 19:02:07.347978	0
925	2019-12-22 19:02:07.347978	0
926	2019-12-22 19:02:07.347978	0
927	2019-12-22 19:02:07.347978	0
928	2019-12-22 19:02:07.347978	0
929	2019-12-22 19:02:07.347978	0
930	2019-12-22 19:02:07.347978	0
931	2019-12-22 19:02:07.347978	0
932	2019-12-22 19:02:07.347978	0
933	2019-12-22 19:02:07.347978	0
934	2019-12-22 19:02:07.347978	0
935	2019-12-22 19:02:07.347978	0
936	2019-12-22 19:02:07.347978	0
937	2019-12-22 19:02:07.347978	0
938	2019-12-22 19:02:07.347978	0
939	2019-12-22 19:02:07.347978	0
940	2019-12-22 19:02:07.347978	0
941	2019-12-22 19:02:07.347978	0
942	2019-12-22 19:02:07.347978	0
943	2019-12-22 19:02:07.347978	0
944	2019-12-22 19:02:07.347978	0
945	2019-12-22 19:02:07.347978	0
946	2019-12-22 19:02:07.347978	0
947	2019-12-22 19:02:07.347978	0
948	2019-12-22 19:02:07.347978	0
949	2019-12-22 19:02:07.347978	0
950	2019-12-22 19:02:07.347978	0
951	2019-12-22 19:02:07.347978	0
952	2019-12-22 19:02:07.347978	207
953	2019-12-22 19:02:07.347978	157
954	2019-12-22 19:02:07.347978	172
955	2019-12-22 19:02:07.347978	158
956	2019-12-22 19:02:07.347978	187
957	2019-12-22 19:02:07.347978	170
958	2019-12-22 19:02:07.347978	259
959	2019-12-22 19:02:07.347978	180
960	2019-12-22 19:02:07.347978	200
961	2019-12-22 19:02:07.347978	184
962	2019-12-22 19:02:07.347978	159
963	2019-12-22 19:02:07.347978	236
964	2019-12-22 19:02:07.347978	248
965	2019-12-22 19:02:07.347978	0
966	2019-12-22 19:02:07.347978	736
967	2019-12-22 19:02:07.347978	733
968	2019-12-22 19:02:07.347978	392
969	2019-12-22 19:02:07.347978	889
970	2019-12-22 19:02:07.347978	755
971	2019-12-22 19:02:07.347978	0
972	2019-12-22 19:02:07.347978	464
973	2019-12-22 19:02:07.347978	564
974	2019-12-22 19:02:07.347978	500
975	2019-12-22 19:02:07.347978	526
976	2019-12-22 19:02:07.347978	434
977	2019-12-22 19:02:07.347978	456
978	2019-12-22 19:02:07.347978	494
979	2019-12-22 19:02:07.347978	0
980	2019-12-22 19:02:07.347978	766
981	2019-12-22 19:02:07.347978	846
982	2019-12-22 19:02:07.347978	521
983	2019-12-22 19:02:07.347978	668
984	2019-12-22 19:02:07.347978	669
985	2019-12-22 19:02:07.347978	217
986	2019-12-22 19:02:07.347978	66
987	2019-12-22 19:02:07.347978	180
988	2019-12-22 19:02:07.347978	167
989	2019-12-22 19:02:07.347978	193
990	2019-12-22 19:02:07.347978	249
991	2019-12-22 19:02:07.347978	132
992	2019-12-22 19:02:07.347978	451
993	2019-12-22 19:02:07.347978	246
994	2019-12-22 19:02:07.347978	202
995	2019-12-22 19:02:07.347978	348
996	2019-12-22 19:02:07.347978	67
997	2019-12-22 19:02:07.347978	240
998	2019-12-22 19:02:07.347978	276
999	2019-12-22 19:02:07.347978	265
1000	2019-12-22 19:02:07.347978	210
1001	2019-12-22 19:02:07.347978	246
1002	2019-12-22 19:02:07.347978	309
1003	2019-12-22 19:02:07.347978	304
1004	2019-12-22 19:02:07.347978	308
1005	2019-12-22 19:02:07.347978	296
1006	2019-12-22 19:02:07.347978	205
1007	2019-12-22 19:02:07.347978	232
1008	2019-12-22 19:02:07.347978	215
1009	2019-12-22 19:02:07.347978	215
1010	2019-12-22 19:02:07.347978	167
1011	2019-12-22 19:02:07.347978	204
1012	2019-12-22 19:02:07.347978	190
1013	2019-12-22 19:02:07.347978	205
1014	2019-12-22 19:02:07.347978	203
1015	2019-12-22 19:02:07.347978	237
1016	2019-12-22 19:02:07.347978	513
1017	2019-12-22 19:02:07.347978	418
1018	2019-12-22 19:02:07.347978	180
1019	2019-12-22 19:02:07.347978	223
1020	2019-12-22 19:02:07.347978	245
1021	2019-12-22 19:02:07.347978	665
1022	2019-12-22 19:02:07.347978	350
1023	2019-12-22 19:02:07.347978	450
1024	2019-12-22 19:02:07.347978	329
1025	2019-12-22 19:02:07.347978	0
1026	2019-12-22 19:02:07.347978	0
1027	2019-12-22 19:02:07.347978	0
1028	2019-12-22 19:02:07.347978	0
1029	2019-12-22 19:02:07.347978	0
1030	2019-12-22 19:02:07.347978	0
1031	2019-12-22 19:02:07.347978	0
1032	2019-12-22 19:02:07.347978	0
1033	2019-12-22 19:02:07.347978	0
1034	2019-12-22 19:02:07.347978	0
1035	2019-12-22 19:02:07.347978	0
1036	2019-12-22 19:02:07.347978	0
1037	2019-12-22 19:02:07.347978	0
1038	2019-12-22 19:02:07.347978	0
1039	2019-12-22 19:02:07.347978	0
1040	2019-12-22 19:02:07.347978	0
1041	2019-12-22 19:02:07.347978	0
1042	2019-12-22 19:02:07.347978	0
1043	2019-12-22 19:02:07.347978	0
1044	2019-12-22 19:02:07.347978	0
1045	2019-12-22 19:02:07.347978	0
1046	2019-12-22 19:02:07.347978	0
1047	2019-12-22 19:02:07.347978	0
1048	2019-12-22 19:02:07.347978	0
1049	2019-12-22 19:02:07.347978	0
1050	2019-12-22 19:02:07.347978	0
1051	2019-12-22 19:02:07.347978	0
1052	2019-12-22 19:02:07.347978	0
1053	2019-12-22 19:02:07.347978	203
1054	2019-12-22 19:02:07.347978	198
1055	2019-12-22 19:02:07.347978	211
1056	2019-12-22 19:02:07.347978	191
1057	2019-12-22 19:02:07.347978	186
1058	2019-12-22 19:02:07.347978	129
1059	2019-12-22 19:02:07.347978	300
1060	2019-12-22 19:02:07.347978	204
1061	2019-12-22 19:02:07.347978	269
1062	2019-12-22 19:02:07.347978	224
1063	2019-12-22 19:02:07.347978	216
1064	2019-12-22 19:02:07.347978	229
1065	2019-12-22 19:02:07.347978	239
1066	2019-12-22 19:02:07.347978	218
1067	2019-12-22 19:02:07.347978	311
1068	2019-12-22 19:02:07.347978	227
1069	2019-12-22 19:02:07.347978	232
1070	2019-12-22 19:02:07.347978	237
1071	2019-12-22 19:02:07.347978	235
1072	2019-12-22 19:02:07.347978	266
1073	2019-12-22 19:02:07.347978	184
1074	2019-12-22 19:02:07.347978	229
1075	2019-12-22 19:02:07.347978	244
1076	2019-12-22 19:02:07.347978	196
1077	2019-12-22 19:02:07.347978	271
1078	2019-12-22 19:02:07.347978	295
1079	2019-12-22 19:02:07.347978	220
1080	2019-12-22 19:02:07.347978	351
1081	2019-12-22 19:02:07.347978	482
1082	2019-12-22 19:02:07.347978	278
1083	2019-12-22 19:02:07.347978	285
1084	2019-12-22 19:02:07.347978	212
1085	2019-12-22 19:02:07.347978	428
1086	2019-12-22 19:02:07.347978	309
1087	2019-12-22 19:02:07.347978	248
1088	2019-12-22 19:02:07.347978	202
1089	2019-12-22 19:02:07.347978	280
1090	2019-12-22 19:02:07.347978	291
1091	2019-12-22 19:02:07.347978	291
1092	2019-12-22 19:02:07.347978	156
1093	2019-12-22 19:02:07.347978	225
1094	2019-12-22 19:02:07.347978	348
1095	2019-12-22 19:02:07.347978	330
1096	2019-12-22 19:02:07.347978	0
1097	2019-12-22 19:02:07.347978	0
1098	2019-12-22 19:02:07.347978	0
1099	2019-12-22 19:02:07.347978	0
1100	2019-12-22 19:02:07.347978	0
1101	2019-12-22 19:02:07.347978	0
1102	2019-12-22 19:02:07.347978	0
1103	2019-12-22 19:02:07.347978	0
1104	2019-12-22 19:02:07.347978	0
1105	2019-12-22 19:02:07.347978	0
1106	2019-12-22 19:02:07.347978	267
1107	2019-12-22 19:02:07.347978	252
1108	2019-12-22 19:02:07.347978	265
1109	2019-12-22 19:02:07.347978	345
1110	2019-12-22 19:02:07.347978	260
1111	2019-12-22 19:02:07.347978	256
1112	2019-12-22 19:02:07.347978	241
1113	2019-12-22 19:02:07.347978	234
1114	2019-12-22 19:02:07.347978	267
1115	2019-12-22 19:02:07.347978	425
1116	2019-12-22 19:02:07.347978	162
1117	2019-12-22 19:02:07.347978	205
1118	2019-12-22 19:02:07.347978	225
1119	2019-12-22 19:02:07.347978	232
1120	2019-12-22 19:02:07.347978	252
1121	2019-12-22 19:02:07.347978	215
1122	2019-12-22 19:02:07.347978	200
1123	2019-12-22 19:02:07.347978	256
1124	2019-12-22 19:02:07.347978	382
1125	2019-12-22 19:02:07.347978	393
1126	2019-12-22 19:02:07.347978	389
1127	2019-12-22 19:02:07.347978	509
1128	2019-12-22 19:02:07.347978	228
1129	2019-12-22 19:02:07.347978	191
1130	2019-12-22 19:02:07.347978	427
1131	2019-12-22 19:02:07.347978	499
1132	2019-12-22 19:02:07.347978	0
1133	2019-12-22 19:02:07.347978	294
1134	2019-12-22 19:02:07.347978	250
1135	2019-12-22 19:02:07.347978	306
1136	2019-12-22 19:02:07.347978	238
1137	2019-12-22 19:02:07.347978	128
1138	2019-12-22 19:02:07.347978	177
1139	2019-12-22 19:02:07.347978	202
1140	2019-12-22 19:02:07.347978	161
1141	2019-12-22 19:02:07.347978	242
1142	2019-12-22 19:02:07.347978	214
1143	2019-12-22 19:02:07.347978	158
1144	2019-12-22 19:02:07.347978	270
1145	2019-12-22 19:02:07.347978	188
1146	2019-12-22 19:02:07.347978	313
1147	2019-12-22 19:02:07.347978	217
1148	2019-12-22 19:02:07.347978	263
1149	2019-12-22 19:02:07.347978	240
1150	2019-12-22 19:02:07.347978	316
1151	2019-12-22 19:02:07.347978	212
1152	2019-12-22 19:02:07.347978	252
1153	2019-12-22 19:02:07.347978	225
1154	2019-12-22 19:02:07.347978	192
1155	2019-12-22 19:02:07.347978	222
1156	2019-12-22 19:02:07.347978	205
1157	2019-12-22 19:02:07.347978	229
1158	2019-12-22 19:02:07.347978	275
1159	2019-12-22 19:02:07.347978	84
1160	2019-12-22 19:02:07.347978	1021
1161	2019-12-22 19:02:07.347978	680
1162	2019-12-22 19:02:07.347978	622
1163	2019-12-22 19:02:07.347978	84
1164	2019-12-22 19:02:07.347978	315
1165	2019-12-22 19:02:07.347978	256
1166	2019-12-22 19:02:07.347978	280
1167	2019-12-22 19:02:07.347978	237
1168	2019-12-22 19:02:07.347978	172
1169	2019-12-22 19:02:07.347978	192
1170	2019-12-22 19:02:07.347978	254
1171	2019-12-22 19:02:07.347978	267
1172	2019-12-22 19:02:07.347978	231
1173	2019-12-22 19:02:07.347978	201
1174	2019-12-22 19:02:07.347978	268
1175	2019-12-22 19:02:07.347978	301
1176	2019-12-22 19:02:07.347978	174
1177	2019-12-22 19:02:07.347978	326
1178	2019-12-22 19:02:07.347978	285
1179	2019-12-22 19:02:07.347978	88
1180	2019-12-22 19:02:07.347978	119
1181	2019-12-22 19:02:07.347978	166
1182	2019-12-22 19:02:07.347978	205
1183	2019-12-22 19:02:07.347978	167
1184	2019-12-22 19:02:07.347978	153
1185	2019-12-22 19:02:07.347978	204
1186	2019-12-22 19:02:07.347978	156
1187	2019-12-22 19:02:07.347978	303
1188	2019-12-22 19:02:07.347978	158
1189	2019-12-22 19:02:07.347978	163
1190	2019-12-22 19:02:07.347978	155
1191	2019-12-22 19:02:07.347978	80
1192	2019-12-22 19:02:07.347978	303
1193	2019-12-22 19:02:07.347978	149
1194	2019-12-22 19:02:07.347978	189
1195	2019-12-22 19:02:07.347978	362
1196	2019-12-22 19:02:07.347978	338
1197	2019-12-22 19:02:07.347978	330
1198	2019-12-22 19:02:07.347978	375
1199	2019-12-22 19:02:07.347978	309
1200	2019-12-22 19:02:07.347978	317
1201	2019-12-22 19:02:07.347978	231
1202	2019-12-22 19:02:07.347978	43
1203	2019-12-22 19:02:07.347978	316
1204	2019-12-22 19:02:07.347978	287
1205	2019-12-22 19:02:07.347978	208
1206	2019-12-22 19:02:07.347978	225
1207	2019-12-22 19:02:07.347978	338
1208	2019-12-22 19:02:07.347978	149
1209	2019-12-22 19:02:07.347978	202
1210	2019-12-22 19:02:07.347978	226
1211	2019-12-22 19:02:07.347978	330
1212	2019-12-22 19:02:07.347978	228
1213	2019-12-22 19:02:07.347978	280
1214	2019-12-22 19:02:07.347978	318
1215	2019-12-22 19:02:07.347978	318
1216	2019-12-22 19:02:07.347978	188
1217	2019-12-22 19:02:07.347978	242
1218	2019-12-22 19:02:07.347978	213
1219	2019-12-22 19:02:07.347978	207
1220	2019-12-22 19:02:07.347978	328
1221	2019-12-22 19:02:07.347978	231
1222	2019-12-22 19:02:07.347978	235
1223	2019-12-22 19:02:07.347978	257
1224	2019-12-22 19:02:07.347978	289
1225	2019-12-22 19:02:07.347978	320
1226	2019-12-22 19:02:07.347978	290
1227	2019-12-22 19:02:07.347978	217
1228	2019-12-22 19:02:07.347978	232
1229	2019-12-22 19:02:07.347978	295
1230	2019-12-22 19:02:07.347978	216
1231	2019-12-22 19:02:07.347978	208
1232	2019-12-22 19:02:07.347978	185
1233	2019-12-22 19:02:07.347978	338
1234	2019-12-22 19:02:07.347978	208
1235	2019-12-22 19:02:07.347978	11
1236	2019-12-22 19:02:07.347978	136
1237	2019-12-22 19:02:07.347978	103
1238	2019-12-22 19:02:07.347978	185
1239	2019-12-22 19:02:07.347978	195
1240	2019-12-22 19:02:07.347978	147
1241	2019-12-22 19:02:07.347978	133
1242	2019-12-22 19:02:07.347978	146
1243	2019-12-22 19:02:07.347978	12
1244	2019-12-22 19:02:07.347978	138
1245	2019-12-22 19:02:07.347978	32
1246	2019-12-22 19:02:07.347978	160
1247	2019-12-22 19:02:07.347978	190
1248	2019-12-22 19:02:07.347978	295
1249	2019-12-22 19:02:07.347978	8
1250	2019-12-22 19:02:07.347978	124
1251	2019-12-22 19:02:07.347978	143
1252	2019-12-22 19:02:07.347978	61
1253	2019-12-22 19:02:07.347978	199
1254	2019-12-22 19:02:07.347978	52
1255	2019-12-22 19:02:07.347978	0
1256	2019-12-22 19:02:07.347978	0
1257	2019-12-22 19:02:07.347978	0
1258	2019-12-22 19:02:07.347978	0
1259	2019-12-22 19:02:07.347978	0
1260	2019-12-22 19:02:07.347978	0
1261	2019-12-22 19:02:07.347978	0
1262	2019-12-22 19:02:07.347978	0
1263	2019-12-22 19:02:07.347978	0
1264	2019-12-22 19:02:07.347978	0
1265	2019-12-22 19:02:07.347978	67
1266	2019-12-22 19:02:07.347978	244
1267	2019-12-22 19:02:07.347978	211
1268	2019-12-22 19:02:07.347978	179
1269	2019-12-22 19:02:07.347978	253
1270	2019-12-22 19:02:07.347978	282
1271	2019-12-22 19:02:07.347978	281
1272	2019-12-22 19:02:07.347978	283
1273	2019-12-22 19:02:07.347978	198
1274	2019-12-22 19:02:07.347978	0
1275	2019-12-22 19:02:07.347978	175
1276	2019-12-22 19:02:07.347978	203
1277	2019-12-22 19:02:07.347978	244
1278	2019-12-22 19:02:07.347978	283
1279	2019-12-22 19:02:07.347978	277
1280	2019-12-22 19:02:07.347978	180
1281	2019-12-22 19:02:07.347978	366
1282	2019-12-22 19:02:07.347978	208
1283	2019-12-22 19:02:07.347978	140
1284	2019-12-22 19:02:07.347978	279
1285	2019-12-22 19:02:07.347978	196
1286	2019-12-22 19:02:07.347978	123
1287	2019-12-22 19:02:07.347978	0
1288	2019-12-22 19:02:07.347978	261
1289	2019-12-22 19:02:07.347978	119
1290	2019-12-22 19:02:07.347978	87
1291	2019-12-22 19:02:07.347978	134
1292	2019-12-22 19:02:07.347978	200
1293	2019-12-22 19:02:07.347978	35
1294	2019-12-22 19:02:07.347978	235
1295	2019-12-22 19:02:07.347978	44
1296	2019-12-22 19:02:07.347978	159
1297	2019-12-22 19:02:07.347978	109
1298	2019-12-22 19:02:07.347978	443
1299	2019-12-22 19:02:07.347978	71
1300	2019-12-22 19:02:07.347978	166
1301	2019-12-22 19:02:07.347978	184
1302	2019-12-22 19:02:07.347978	164
1303	2019-12-22 19:02:07.347978	131
1304	2019-12-22 19:02:07.347978	137
1305	2019-12-22 19:02:07.347978	211
1306	2019-12-22 19:02:07.347978	173
1307	2019-12-22 19:02:07.347978	237
1308	2019-12-22 19:02:07.347978	196
1309	2019-12-22 19:02:07.347978	233
1310	2019-12-22 19:02:07.347978	199
1311	2019-12-22 19:02:07.347978	175
1312	2019-12-22 19:02:07.347978	181
1313	2019-12-22 19:02:07.347978	234
1314	2019-12-22 19:02:07.347978	123
1315	2019-12-22 19:02:07.347978	201
1316	2019-12-22 19:02:07.347978	0
1317	2019-12-22 19:02:07.347978	0
1318	2019-12-22 19:02:07.347978	0
1319	2019-12-22 19:02:07.347978	0
1320	2019-12-22 19:02:07.347978	0
1321	2019-12-22 19:02:07.347978	0
1322	2019-12-22 19:02:07.347978	0
1323	2019-12-22 19:02:07.347978	0
1324	2019-12-22 19:02:07.347978	0
1325	2019-12-22 19:02:07.347978	0
1326	2019-12-22 19:02:07.347978	0
1327	2019-12-22 19:02:07.347978	410
1328	2019-12-22 19:02:07.347978	268
1329	2019-12-22 19:02:07.347978	223
1330	2019-12-22 19:02:07.347978	246
1331	2019-12-22 19:02:07.347978	228
1332	2019-12-22 19:02:07.347978	256
1333	2019-12-22 19:02:07.347978	191
1334	2019-12-22 19:02:07.347978	217
1335	2019-12-22 19:02:07.347978	213
1336	2019-12-22 19:02:07.347978	278
1337	2019-12-22 19:02:07.347978	182
1338	2019-12-22 19:02:07.347978	166
1339	2019-12-22 19:02:07.347978	210
1340	2019-12-22 19:02:07.347978	203
1341	2019-12-22 19:02:07.347978	195
1342	2019-12-22 19:02:07.347978	175
1343	2019-12-22 19:02:07.347978	235
1344	2019-12-22 19:02:07.347978	201
1345	2019-12-22 19:02:07.347978	154
1346	2019-12-22 19:02:07.347978	400
1347	2019-12-22 19:02:07.347978	195
1348	2019-12-22 19:02:07.347978	235
1349	2019-12-22 19:02:07.347978	0
1350	2019-12-22 19:02:07.347978	0
1351	2019-12-22 19:02:07.347978	0
1352	2019-12-22 19:02:07.347978	0
1353	2019-12-22 19:02:07.347978	0
1354	2019-12-22 19:02:07.347978	0
1355	2019-12-22 19:02:07.347978	0
1356	2019-12-22 19:02:07.347978	0
1357	2019-12-22 19:02:07.347978	0
1358	2019-12-22 19:02:07.347978	0
1359	2019-12-22 19:02:07.347978	0
1360	2019-12-22 19:02:07.347978	0
1361	2019-12-22 19:02:07.347978	0
1362	2019-12-22 19:02:07.347978	216
1363	2019-12-22 19:02:07.347978	200
1364	2019-12-22 19:02:07.347978	252
1365	2019-12-22 19:02:07.347978	243
1366	2019-12-22 19:02:07.347978	266
1367	2019-12-22 19:02:07.347978	231
1368	2019-12-22 19:02:07.347978	282
1369	2019-12-22 19:02:07.347978	370
1370	2019-12-22 19:02:07.347978	259
1371	2019-12-22 19:02:07.347978	241
1372	2019-12-22 19:02:07.347978	230
1373	2019-12-22 19:02:07.347978	283
1374	2019-12-22 19:02:07.347978	310
1375	2019-12-22 19:02:07.347978	279
1376	2019-12-22 19:02:07.347978	280
1377	2019-12-22 19:02:07.347978	246
1378	2019-12-22 19:02:07.347978	395
1379	2019-12-22 19:02:07.347978	147
1380	2019-12-22 19:02:07.347978	247
1381	2019-12-22 19:02:07.347978	240
1382	2019-12-22 19:02:07.347978	194
1383	2019-12-22 19:02:07.347978	166
1384	2019-12-22 19:02:07.347978	263
1385	2019-12-22 19:02:07.347978	157
1386	2019-12-22 19:02:07.347978	286
1387	2019-12-22 19:02:07.347978	277
1388	2019-12-22 19:02:07.347978	398
1389	2019-12-22 19:02:07.347978	166
1390	2019-12-22 19:02:07.347978	402
1391	2019-12-22 19:02:07.347978	388
1392	2019-12-22 19:02:07.347978	388
1393	2019-12-22 19:02:07.347978	274
1394	2019-12-22 19:02:07.347978	132
1395	2019-12-22 19:02:07.347978	150
1396	2019-12-22 19:02:07.347978	282
1397	2019-12-22 19:02:07.347978	507
1398	2019-12-22 19:02:07.347978	165
1399	2019-12-22 19:02:07.347978	240
1400	2019-12-22 19:02:07.347978	130
1401	2019-12-22 19:02:07.347978	190
1402	2019-12-22 19:02:07.347978	62
1403	2019-12-22 19:02:07.347978	185
1404	2019-12-22 19:02:07.347978	286
1405	2019-12-22 19:02:07.347978	167
1406	2019-12-22 19:02:07.347978	148
1407	2019-12-22 19:02:07.347978	121
1408	2019-12-22 19:02:07.347978	140
1409	2019-12-22 19:02:07.347978	124
1410	2019-12-22 19:02:07.347978	213
1411	2019-12-22 19:02:07.347978	232
1412	2019-12-22 19:02:07.347978	102
1413	2019-12-22 19:02:07.347978	106
1414	2019-12-22 19:02:07.347978	177
1415	2019-12-22 19:02:07.347978	160
1416	2019-12-22 19:02:07.347978	241
1417	2019-12-22 19:02:07.347978	166
1418	2019-12-22 19:02:07.347978	145
1419	2019-12-22 19:02:07.347978	195
1420	2019-12-22 19:02:07.347978	270
1421	2019-12-22 19:02:07.347978	188
1422	2019-12-22 19:02:07.347978	253
1423	2019-12-22 19:02:07.347978	162
1424	2019-12-22 19:02:07.347978	175
1425	2019-12-22 19:02:07.347978	191
1426	2019-12-22 19:02:07.347978	495
1427	2019-12-22 19:02:07.347978	194
1428	2019-12-22 19:02:07.347978	0
1429	2019-12-22 19:02:07.347978	0
1430	2019-12-22 19:02:07.347978	0
1431	2019-12-22 19:02:07.347978	0
1432	2019-12-22 19:02:07.347978	0
1433	2019-12-22 19:02:07.347978	0
1434	2019-12-22 19:02:07.347978	0
1435	2019-12-22 19:02:07.347978	0
1436	2019-12-22 19:02:07.347978	0
1437	2019-12-22 19:02:07.347978	306
1438	2019-12-22 19:02:07.347978	382
1439	2019-12-22 19:02:07.347978	372
1440	2019-12-22 19:02:07.347978	307
1441	2019-12-22 19:02:07.347978	234
1442	2019-12-22 19:02:07.347978	299
1443	2019-12-22 19:02:07.347978	331
1444	2019-12-22 19:02:07.347978	214
1445	2019-12-22 19:02:07.347978	352
1446	2019-12-22 19:02:07.347978	259
1447	2019-12-22 19:02:07.347978	286
1448	2019-12-22 19:02:07.347978	292
1449	2019-12-22 19:02:07.347978	347
1450	2019-12-22 19:02:07.347978	307
1451	2019-12-22 19:02:07.347978	422
1452	2019-12-22 19:02:07.347978	350
1453	2019-12-22 19:02:07.347978	295
1454	2019-12-22 19:02:07.347978	220
1455	2019-12-22 19:02:07.347978	351
1456	2019-12-22 19:02:07.347978	482
1457	2019-12-22 19:02:07.347978	278
1458	2019-12-22 19:02:07.347978	285
1459	2019-12-22 19:02:07.347978	212
1460	2019-12-22 19:02:07.347978	428
1461	2019-12-22 19:02:07.347978	0
1462	2019-12-22 19:02:07.347978	0
1463	2019-12-22 19:02:07.347978	0
1464	2019-12-22 19:02:07.347978	0
1465	2019-12-22 19:02:07.347978	0
1466	2019-12-22 19:02:07.347978	0
1467	2019-12-22 19:02:07.347978	0
1468	2019-12-22 19:02:07.347978	0
1469	2019-12-22 19:02:07.347978	0
1470	2019-12-22 19:02:07.347978	0
1471	2019-12-22 19:02:07.347978	0
1472	2019-12-22 19:02:07.347978	0
1473	2019-12-22 19:02:07.347978	0
1474	2019-12-22 19:02:07.347978	0
1475	2019-12-22 19:02:07.347978	0
1476	2019-12-22 19:02:07.347978	0
1477	2019-12-22 19:02:07.347978	0
1478	2019-12-22 19:02:07.347978	0
1479	2019-12-22 19:02:07.347978	0
1480	2019-12-22 19:02:07.347978	0
1481	2019-12-22 19:02:07.347978	0
1482	2019-12-22 19:02:07.347978	0
1483	2019-12-22 19:02:07.347978	0
1484	2019-12-22 19:02:07.347978	0
1485	2019-12-22 19:02:07.347978	260
1486	2019-12-22 19:02:07.347978	198
1487	2019-12-22 19:02:07.347978	280
1488	2019-12-22 19:02:07.347978	250
1489	2019-12-22 19:02:07.347978	469
1490	2019-12-22 19:02:07.347978	275
1491	2019-12-22 19:02:07.347978	190
1492	2019-12-22 19:02:07.347978	297
1493	2019-12-22 19:02:07.347978	252
1494	2019-12-22 19:02:07.347978	434
1495	2019-12-22 19:02:07.347978	0
1496	2019-12-22 19:02:07.347978	105
1497	2019-12-22 19:02:07.347978	293
1498	2019-12-22 19:02:07.347978	209
1499	2019-12-22 19:02:07.347978	290
1500	2019-12-22 19:02:07.347978	260
1501	2019-12-22 19:02:07.347978	0
1502	2019-12-22 19:02:07.347978	247
1503	2019-12-22 19:02:07.347978	324
1504	2019-12-22 19:02:07.347978	198
1505	2019-12-22 19:02:07.347978	253
1506	2019-12-22 19:02:07.347978	202
1507	2019-12-22 19:02:07.347978	351
1508	2019-12-22 19:02:07.347978	304
1509	2019-12-22 19:02:07.347978	448
1510	2019-12-22 19:02:07.347978	332
1511	2019-12-22 19:02:07.347978	250
1512	2019-12-22 19:02:07.347978	270
1513	2019-12-22 19:02:07.347978	314
1514	2019-12-22 19:02:07.347978	309
1515	2019-12-22 19:02:07.347978	314
1516	2019-12-22 19:02:07.347978	213
1517	2019-12-22 19:02:07.347978	210
1518	2019-12-22 19:02:07.347978	252
1519	2019-12-22 19:02:07.347978	253
1520	2019-12-22 19:02:07.347978	208
1521	2019-12-22 19:02:07.347978	237
1522	2019-12-22 19:02:07.347978	243
1523	2019-12-22 19:02:07.347978	252
1524	2019-12-22 19:02:07.347978	205
1525	2019-12-22 19:02:07.347978	281
1526	2019-12-22 19:02:07.347978	406
1527	2019-12-22 19:02:07.347978	211
1528	2019-12-22 19:02:07.347978	166
1529	2019-12-22 19:02:07.347978	220
1530	2019-12-22 19:02:07.347978	222
1531	2019-12-22 19:02:07.347978	326
1532	2019-12-22 19:02:07.347978	501
1533	2019-12-22 19:02:07.347978	75
1534	2019-12-22 19:02:07.347978	282
1535	2019-12-22 19:02:07.347978	290
1536	2019-12-22 19:02:07.347978	190
1537	2019-12-22 19:02:07.347978	136
1538	2019-12-22 19:02:07.347978	223
1539	2019-12-22 19:02:07.347978	168
1540	2019-12-22 19:02:07.347978	185
1541	2019-12-22 19:02:07.347978	160
1542	2019-12-22 19:02:07.347978	60
1543	2019-12-22 19:02:07.347978	256
1544	2019-12-22 19:02:07.347978	259
1545	2019-12-22 19:02:07.347978	340
1546	2019-12-22 19:02:07.347978	258
1547	2019-12-22 19:02:07.347978	276
1548	2019-12-22 19:02:07.347978	465
1549	2019-12-22 19:02:07.347978	178
1550	2019-12-22 19:02:07.347978	259
1551	2019-12-22 19:02:07.347978	530
1552	2019-12-22 19:02:07.347978	286
1553	2019-12-22 19:02:07.347978	299
1554	2019-12-22 19:02:07.347978	209
1555	2019-12-22 19:02:07.347978	154
1556	2019-12-22 19:02:07.347978	212
1557	2019-12-22 19:02:07.347978	157
1558	2019-12-22 19:02:07.347978	238
1559	2019-12-22 19:02:07.347978	187
1560	2019-12-22 19:02:07.347978	192
1561	2019-12-22 19:02:07.347978	197
1562	2019-12-22 19:02:07.347978	227
1563	2019-12-22 19:02:07.347978	216
1564	2019-12-22 19:02:07.347978	207
1565	2019-12-22 19:02:07.347978	196
1566	2019-12-22 19:02:07.347978	350
1567	2019-12-22 19:02:07.347978	310
1568	2019-12-22 19:02:07.347978	363
1569	2019-12-22 19:02:07.347978	222
1570	2019-12-22 19:02:07.347978	129
1571	2019-12-22 19:02:07.347978	1411
1572	2019-12-22 19:02:07.347978	0
1573	2019-12-22 19:02:07.347978	0
1574	2019-12-22 19:02:07.347978	0
1575	2019-12-22 19:02:07.347978	0
1576	2019-12-22 19:02:07.347978	0
1577	2019-12-22 19:02:07.347978	0
1578	2019-12-22 19:02:07.347978	0
1579	2019-12-22 19:02:07.347978	0
1580	2019-12-22 19:02:07.347978	0
1581	2019-12-22 19:02:07.347978	0
1582	2019-12-22 19:02:07.347978	0
1583	2019-12-22 19:02:07.347978	0
1584	2019-12-22 19:02:07.347978	0
1585	2019-12-22 19:02:07.347978	410
1586	2019-12-22 19:02:07.347978	172
1587	2019-12-22 19:02:07.347978	115
1588	2019-12-22 19:02:07.347978	124
1589	2019-12-22 19:02:07.347978	154
1590	2019-12-22 19:02:07.347978	201
1591	2019-12-22 19:02:07.347978	141
1592	2019-12-22 19:02:07.347978	177
1593	2019-12-22 19:02:07.347978	125
1594	2019-12-22 19:02:07.347978	84
1595	2019-12-22 19:02:07.347978	163
1596	2019-12-22 19:02:07.347978	231
1597	2019-12-22 19:02:07.347978	109
1598	2019-12-22 19:02:07.347978	211
1599	2019-12-22 19:02:07.347978	145
1600	2019-12-22 19:02:07.347978	165
1601	2019-12-22 19:02:07.347978	158
1602	2019-12-22 19:02:07.347978	298
1603	2019-12-22 19:02:07.347978	202
1604	2019-12-22 19:02:07.347978	106
1605	2019-12-22 19:02:07.347978	196
1606	2019-12-22 19:02:07.347978	277
1607	2019-12-22 19:02:07.347978	234
1608	2019-12-22 19:02:07.347978	121
1609	2019-12-22 19:02:07.347978	195
1610	2019-12-22 19:02:07.347978	175
1611	2019-12-22 19:02:07.347978	189
1612	2019-12-22 19:02:07.347978	0
1613	2019-12-22 19:02:07.347978	0
1614	2019-12-22 19:02:07.347978	0
1615	2019-12-22 19:02:07.347978	0
1616	2019-12-22 19:02:07.347978	0
1617	2019-12-22 19:02:07.347978	0
1618	2019-12-22 19:02:07.347978	0
1619	2019-12-22 19:02:07.347978	0
1620	2019-12-22 19:02:07.347978	0
1621	2019-12-22 19:02:07.347978	0
1622	2019-12-22 19:02:07.347978	0
1623	2019-12-22 19:02:07.347978	0
1624	2019-12-22 19:02:07.347978	0
1625	2019-12-22 19:02:07.347978	0
1626	2019-12-22 19:02:07.347978	0
1627	2019-12-22 19:02:07.347978	0
1628	2019-12-22 19:02:07.347978	0
1629	2019-12-22 19:02:07.347978	0
1630	2019-12-22 19:02:07.347978	0
1631	2019-12-22 19:02:07.347978	0
1632	2019-12-22 19:02:07.347978	0
1633	2019-12-22 19:02:07.347978	0
1634	2019-12-22 19:02:07.347978	0
1635	2019-12-22 19:02:07.347978	0
1636	2019-12-22 19:02:07.347978	0
1637	2019-12-22 19:02:07.347978	0
1638	2019-12-22 19:02:07.347978	0
1639	2019-12-22 19:02:07.347978	0
1640	2019-12-22 19:02:07.347978	0
1641	2019-12-22 19:02:07.347978	203
1642	2019-12-22 19:02:07.347978	215
1643	2019-12-22 19:02:07.347978	240
1644	2019-12-22 19:02:07.347978	183
1645	2019-12-22 19:02:07.347978	120
1646	2019-12-22 19:02:07.347978	304
1647	2019-12-22 19:02:07.347978	253
1648	2019-12-22 19:02:07.347978	299
1649	2019-12-22 19:02:07.347978	312
1650	2019-12-22 19:02:07.347978	251
1651	2019-12-22 19:02:07.347978	164
1652	2019-12-22 19:02:07.347978	28
1653	2019-12-22 19:02:07.347978	326
1654	2019-12-22 19:02:07.347978	328
1655	2019-12-22 19:02:07.347978	295
1656	2019-12-22 19:02:07.347978	243
1657	2019-12-22 19:02:07.347978	427
1658	2019-12-22 19:02:07.347978	446
1659	2019-12-22 19:02:07.347978	172
1660	2019-12-22 19:02:07.347978	360
1661	2019-12-22 19:02:07.347978	452
1662	2019-12-22 19:02:07.347978	120
1663	2019-12-22 19:02:07.347978	413
1664	2019-12-22 19:02:07.347978	272
1665	2019-12-22 19:02:07.347978	315
1666	2019-12-22 19:02:07.347978	50
1667	2019-12-22 19:02:07.347978	152
1668	2019-12-22 19:02:07.347978	364
1669	2019-12-22 19:02:07.347978	225
1670	2019-12-22 19:02:07.347978	165
1671	2019-12-22 19:02:07.347978	303
1672	2019-12-22 19:02:07.347978	422
1673	2019-12-22 19:02:07.347978	250
1674	2019-12-22 19:02:07.347978	194
1675	2019-12-22 19:02:07.347978	321
1676	2019-12-22 19:02:07.347978	171
1677	2019-12-22 19:02:07.347978	288
1678	2019-12-22 19:02:07.347978	193
1679	2019-12-22 19:02:07.347978	288
1680	2019-12-22 19:02:07.347978	234
1681	2019-12-22 19:02:07.347978	182
1682	2019-12-22 19:02:07.347978	173
1683	2019-12-22 19:02:07.347978	222
1684	2019-12-22 19:02:07.347978	204
1685	2019-12-22 19:02:07.347978	0
1686	2019-12-22 19:02:07.347978	341
1687	2019-12-22 19:02:07.347978	191
1688	2019-12-22 19:02:07.347978	229
1689	2019-12-22 19:02:07.347978	128
1690	2019-12-22 19:02:07.347978	272
1691	2019-12-22 19:02:07.347978	390
1692	2019-12-22 19:02:07.347978	261
1693	2019-12-22 19:02:07.347978	206
1694	2019-12-22 19:02:07.347978	255
1695	2019-12-22 19:02:07.347978	277
1696	2019-12-22 19:02:07.347978	430
1697	2019-12-22 19:02:07.347978	201
1698	2019-12-22 19:02:07.347978	273
1699	2019-12-22 19:02:07.347978	215
1700	2019-12-22 19:02:07.347978	293
1701	2019-12-22 19:02:07.347978	220
1702	2019-12-22 19:02:07.347978	160
1703	2019-12-22 19:02:07.347978	272
1704	2019-12-22 19:02:07.347978	205
1705	2019-12-22 19:02:07.347978	286
1706	2019-12-22 19:02:07.347978	0
1707	2019-12-22 19:02:07.347978	0
1708	2019-12-22 19:02:07.347978	0
1709	2019-12-22 19:02:07.347978	0
1710	2019-12-22 19:02:07.347978	0
1711	2019-12-22 19:02:07.347978	0
1712	2019-12-22 19:02:07.347978	0
1713	2019-12-22 19:02:07.347978	0
1714	2019-12-22 19:02:07.347978	0
1715	2019-12-22 19:02:07.347978	0
1716	2019-12-22 19:02:07.347978	0
1717	2019-12-22 19:02:07.347978	0
1718	2019-12-22 19:02:07.347978	0
1719	2019-12-22 19:02:07.347978	0
1720	2019-12-22 19:02:07.347978	0
1721	2019-12-22 19:02:07.347978	153
1722	2019-12-22 19:02:07.347978	308
1723	2019-12-22 19:02:07.347978	188
1724	2019-12-22 19:02:07.347978	183
1725	2019-12-22 19:02:07.347978	244
1726	2019-12-22 19:02:07.347978	357
1727	2019-12-22 19:02:07.347978	246
1728	2019-12-22 19:02:07.347978	258
1729	2019-12-22 19:02:07.347978	715
1730	2019-12-22 19:02:07.347978	97
1731	2019-12-22 19:02:07.347978	307
1732	2019-12-22 19:02:07.347978	476
1733	2019-12-22 19:02:07.347978	446
1734	2019-12-22 19:02:07.347978	238
1735	2019-12-22 19:02:07.347978	331
1736	2019-12-22 19:02:07.347978	303
1737	2019-12-22 19:02:07.347978	270
1738	2019-12-22 19:02:07.347978	243
1739	2019-12-22 19:02:07.347978	201
1740	2019-12-22 19:02:07.347978	213
1741	2019-12-22 19:02:07.347978	144
1742	2019-12-22 19:02:07.347978	231
1743	2019-12-22 19:02:07.347978	187
1744	2019-12-22 19:02:07.347978	249
1745	2019-12-22 19:02:07.347978	173
1746	2019-12-22 19:02:07.347978	135
1747	2019-12-22 19:02:07.347978	309
1748	2019-12-22 19:02:07.347978	201
1749	2019-12-22 19:02:07.347978	77
1750	2019-12-22 19:02:07.347978	166
1751	2019-12-22 19:02:07.347978	166
1752	2019-12-22 19:02:07.347978	156
1753	2019-12-22 19:02:07.347978	161
1754	2019-12-22 19:02:07.347978	313
1755	2019-12-22 19:02:07.347978	212
1756	2019-12-22 19:02:07.347978	247
1757	2019-12-22 19:02:07.347978	174
1758	2019-12-22 19:02:07.347978	237
1759	2019-12-22 19:02:07.347978	215
1760	2019-12-22 19:02:07.347978	28
1761	2019-12-22 19:02:07.347978	665
1762	2019-12-22 19:02:07.347978	221
1763	2019-12-22 19:02:07.347978	310
1764	2019-12-22 19:02:07.347978	193
1765	2019-12-22 19:02:07.347978	138
1766	2019-12-22 19:02:07.347978	243
1767	2019-12-22 19:02:07.347978	216
1768	2019-12-22 19:02:07.347978	359
1769	2019-12-22 19:02:07.347978	232
1770	2019-12-22 19:02:07.347978	264
1771	2019-12-22 19:02:07.347978	303
1772	2019-12-22 19:02:07.347978	313
1773	2019-12-22 19:02:07.347978	161
1774	2019-12-22 19:02:07.347978	290
1775	2019-12-22 19:02:07.347978	250
1776	2019-12-22 19:02:07.347978	225
1777	2019-12-22 19:02:07.347978	169
1778	2019-12-22 19:02:07.347978	449
1779	2019-12-22 19:02:07.347978	439
1780	2019-12-22 19:02:07.347978	238
1781	2019-12-22 19:02:07.347978	270
1782	2019-12-22 19:02:07.347978	217
1783	2019-12-22 19:02:07.347978	256
1784	2019-12-22 19:02:07.347978	197
1785	2019-12-22 19:02:07.347978	321
1786	2019-12-22 19:02:07.347978	231
1787	2019-12-22 19:02:07.347978	164
1788	2019-12-22 19:02:07.347978	240
1789	2019-12-22 19:02:07.347978	158
1790	2019-12-22 19:02:07.347978	225
1791	2019-12-22 19:02:07.347978	292
1792	2019-12-22 19:02:07.347978	253
1793	2019-12-22 19:02:07.347978	112
1794	2019-12-22 19:02:07.347978	205
1795	2019-12-22 19:02:07.347978	335
1796	2019-12-22 19:02:07.347978	278
1797	2019-12-22 19:02:07.347978	297
1798	2019-12-22 19:02:07.347978	272
1799	2019-12-22 19:02:07.347978	260
1800	2019-12-22 19:02:07.347978	291
1801	2019-12-22 19:02:07.347978	237
1802	2019-12-22 19:02:07.347978	212
1803	2019-12-22 19:02:07.347978	324
1804	2019-12-22 19:02:07.347978	254
1805	2019-12-22 19:02:07.347978	314
1806	2019-12-22 19:02:07.347978	272
1807	2019-12-22 19:02:07.347978	260
1808	2019-12-22 19:02:07.347978	265
1809	2019-12-22 19:02:07.347978	337
1810	2019-12-22 19:02:07.347978	298
1811	2019-12-22 19:02:07.347978	312
1812	2019-12-22 19:02:07.347978	332
1813	2019-12-22 19:02:07.347978	392
1814	2019-12-22 19:02:07.347978	385
1815	2019-12-22 19:02:07.347978	146
1816	2019-12-22 19:02:07.347978	233
1817	2019-12-22 19:02:07.347978	210
1818	2019-12-22 19:02:07.347978	444
1819	2019-12-22 19:02:07.347978	247
1820	2019-12-22 19:02:07.347978	297
1821	2019-12-22 19:02:07.347978	191
1822	2019-12-22 19:02:07.347978	337
1823	2019-12-22 19:02:07.347978	257
1824	2019-12-22 19:02:07.347978	222
1825	2019-12-22 19:02:07.347978	300
1826	2019-12-22 19:02:07.347978	201
1827	2019-12-22 19:02:07.347978	193
1828	2019-12-22 19:02:07.347978	233
1829	2019-12-22 19:02:07.347978	222
1830	2019-12-22 19:02:07.347978	252
1831	2019-12-22 19:02:07.347978	279
1832	2019-12-22 19:02:07.347978	381
1833	2019-12-22 19:02:07.347978	308
1834	2019-12-22 19:02:07.347978	345
1835	2019-12-22 19:02:07.347978	296
1836	2019-12-22 19:02:07.347978	239
1837	2019-12-22 19:02:07.347978	252
1838	2019-12-22 19:02:07.347978	261
1839	2019-12-22 19:02:07.347978	256
1840	2019-12-22 19:02:07.347978	570
1841	2019-12-22 19:02:07.347978	262
1842	2019-12-22 19:02:07.347978	238
1843	2019-12-22 19:02:07.347978	257
1844	2019-12-22 19:02:07.347978	290
1845	2019-12-22 19:02:07.347978	187
1846	2019-12-22 19:02:07.347978	231
1847	2019-12-22 19:02:07.347978	232
1848	2019-12-22 19:02:07.347978	276
1849	2019-12-22 19:02:07.347978	208
1850	2019-12-22 19:02:07.347978	243
1851	2019-12-22 19:02:07.347978	222
1852	2019-12-22 19:02:07.347978	253
1853	2019-12-22 19:02:07.347978	276
1854	2019-12-22 19:02:07.347978	329
1855	2019-12-22 19:02:07.347978	239
1856	2019-12-22 19:02:07.347978	367
1857	2019-12-22 19:02:07.347978	301
1858	2019-12-22 19:02:07.347978	349
1859	2019-12-22 19:02:07.347978	360
1860	2019-12-22 19:02:07.347978	118
1861	2019-12-22 19:02:07.347978	40
1862	2019-12-22 19:02:07.347978	322
1863	2019-12-22 19:02:07.347978	271
1864	2019-12-22 19:02:07.347978	209
1865	2019-12-22 19:02:07.347978	240
1866	2019-12-22 19:02:07.347978	274
1867	2019-12-22 19:02:07.347978	225
1868	2019-12-22 19:02:07.347978	188
1869	2019-12-22 19:02:07.347978	266
1870	2019-12-22 19:02:07.347978	72
1871	2019-12-22 19:02:07.347978	185
1872	2019-12-22 19:02:07.347978	240
1873	2019-12-22 19:02:07.347978	300
1874	2019-12-22 19:02:07.347978	1194
1875	2019-12-22 19:02:07.347978	1198
1876	2019-12-22 19:02:07.347978	390
1877	2019-12-22 19:02:07.347978	391
1878	2019-12-22 19:02:07.347978	0
1879	2019-12-22 19:02:07.347978	0
1880	2019-12-22 19:02:07.347978	0
1881	2019-12-22 19:02:07.347978	0
1882	2019-12-22 19:02:07.347978	0
1883	2019-12-22 19:02:07.347978	0
1884	2019-12-22 19:02:07.347978	0
1885	2019-12-22 19:02:07.347978	0
1886	2019-12-22 19:02:07.347978	0
1887	2019-12-22 19:02:07.347978	0
1888	2019-12-22 19:02:07.347978	0
1889	2019-12-22 19:02:07.347978	0
1890	2019-12-22 19:02:07.347978	0
1891	2019-12-22 19:02:07.347978	0
1892	2019-12-22 19:02:07.347978	0
1893	2019-12-22 19:02:07.347978	0
1894	2019-12-22 19:02:07.347978	360
1895	2019-12-22 19:02:07.347978	101
1896	2019-12-22 19:02:07.347978	266
1897	2019-12-22 19:02:07.347978	400
1898	2019-12-22 19:02:07.347978	254
1899	2019-12-22 19:02:07.347978	245
1900	2019-12-22 19:02:07.347978	174
1901	2019-12-22 19:02:07.347978	222
1902	2019-12-22 19:02:07.347978	192
1903	2019-12-22 19:02:07.347978	184
1904	2019-12-22 19:02:07.347978	171
1905	2019-12-22 19:02:07.347978	184
1906	2019-12-22 19:02:07.347978	169
1907	2019-12-22 19:02:07.347978	189
1908	2019-12-22 19:02:07.347978	58
1909	2019-12-22 19:02:07.347978	247
1910	2019-12-22 19:02:07.347978	243
1911	2019-12-22 19:02:07.347978	235
1912	2019-12-22 19:02:07.347978	230
1913	2019-12-22 19:02:07.347978	259
1914	2019-12-22 19:02:07.347978	212
1915	2019-12-22 19:02:07.347978	232
1916	2019-12-22 19:02:07.347978	228
1917	2019-12-22 19:02:07.347978	272
1918	2019-12-22 19:02:07.347978	155
1919	2019-12-22 19:02:07.347978	203
1920	2019-12-22 19:02:07.347978	150
1921	2019-12-22 19:02:07.347978	241
1922	2019-12-22 19:02:07.347978	286
1923	2019-12-22 19:02:07.347978	332
1924	2019-12-22 19:02:07.347978	456
1925	2019-12-22 19:02:07.347978	189
1926	2019-12-22 19:02:07.347978	313
1927	2019-12-22 19:02:07.347978	264
1928	2019-12-22 19:02:07.347978	305
1929	2019-12-22 19:02:07.347978	231
1930	2019-12-22 19:02:07.347978	0
1931	2019-12-22 19:02:07.347978	0
1932	2019-12-22 19:02:07.347978	0
1933	2019-12-22 19:02:07.347978	0
1934	2019-12-22 19:02:07.347978	0
1935	2019-12-22 19:02:07.347978	0
1936	2019-12-22 19:02:07.347978	0
1937	2019-12-22 19:02:07.347978	0
1938	2019-12-22 19:02:07.347978	0
1939	2019-12-22 19:02:07.347978	0
1940	2019-12-22 19:02:07.347978	0
1941	2019-12-22 19:02:07.347978	0
1942	2019-12-22 19:02:07.347978	0
1943	2019-12-22 19:02:07.347978	0
1944	2019-12-22 19:02:07.347978	0
1945	2019-12-22 19:02:07.347978	0
1946	2019-12-22 19:02:07.347978	0
1947	2019-12-22 19:02:07.347978	0
1948	2019-12-22 19:02:07.347978	0
1949	2019-12-22 19:02:07.347978	0
1950	2019-12-22 19:02:07.347978	0
1951	2019-12-22 19:02:07.347978	0
1952	2019-12-22 19:02:07.347978	0
1953	2019-12-22 19:02:07.347978	0
1954	2019-12-22 19:02:07.347978	0
1955	2019-12-22 19:02:07.347978	0
1956	2019-12-22 19:02:07.347978	0
1957	2019-12-22 19:02:07.347978	0
1958	2019-12-22 19:02:07.347978	0
1959	2019-12-22 19:02:07.347978	240
1960	2019-12-22 19:02:07.347978	232
1961	2019-12-22 19:02:07.347978	312
1962	2019-12-22 19:02:07.347978	193
1963	2019-12-22 19:02:07.347978	295
1964	2019-12-22 19:02:07.347978	280
1965	2019-12-22 19:02:07.347978	310
1966	2019-12-22 19:02:07.347978	333
1967	2019-12-22 19:02:07.347978	199
1968	2019-12-22 19:02:07.347978	236
1969	2019-12-22 19:02:07.347978	218
1970	2019-12-22 19:02:07.347978	173
1971	2019-12-22 19:02:07.347978	176
1972	2019-12-22 19:02:07.347978	142
1973	2019-12-22 19:02:07.347978	130
1974	2019-12-22 19:02:07.347978	170
1975	2019-12-22 19:02:07.347978	132
1976	2019-12-22 19:02:07.347978	142
1977	2019-12-22 19:02:07.347978	146
1978	2019-12-22 19:02:07.347978	265
1979	2019-12-22 19:02:07.347978	197
1980	2019-12-22 19:02:07.347978	191
1981	2019-12-22 19:02:07.347978	327
1982	2019-12-22 19:02:07.347978	223
1983	2019-12-22 19:02:07.347978	177
1984	2019-12-22 19:02:07.347978	146
1985	2019-12-22 19:02:07.347978	322
1986	2019-12-22 19:02:07.347978	156
1987	2019-12-22 19:02:07.347978	285
1988	2019-12-22 19:02:07.347978	189
1989	2019-12-22 19:02:07.347978	186
1990	2019-12-22 19:02:07.347978	321
1991	2019-12-22 19:02:07.347978	161
1992	2019-12-22 19:02:07.347978	89
1993	2019-12-22 19:02:07.347978	199
1994	2019-12-22 19:02:07.347978	180
1995	2019-12-22 19:02:07.347978	177
1996	2019-12-22 19:02:07.347978	253
1997	2019-12-22 19:02:07.347978	191
1998	2019-12-22 19:02:07.347978	219
1999	2019-12-22 19:02:07.347978	227
2000	2019-12-22 19:02:07.347978	23
2001	2019-12-22 19:02:07.347978	208
2002	2019-12-22 19:02:07.347978	219
2003	2019-12-22 19:02:07.347978	187
2004	2019-12-22 19:02:07.347978	247
2005	2019-12-22 19:02:07.347978	11
2006	2019-12-22 19:02:07.347978	754
2007	2019-12-22 19:02:07.347978	216
2008	2019-12-22 19:02:07.347978	269
2009	2019-12-22 19:02:07.347978	194
2010	2019-12-22 19:02:07.347978	169
2011	2019-12-22 19:02:07.347978	353
2012	2019-12-22 19:02:07.347978	303
2013	2019-12-22 19:02:07.347978	127
2014	2019-12-22 19:02:07.347978	264
2015	2019-12-22 19:02:07.347978	149
2016	2019-12-22 19:02:07.347978	487
2017	2019-12-22 19:02:07.347978	185
2018	2019-12-22 19:02:07.347978	275
2019	2019-12-22 19:02:07.347978	260
2020	2019-12-22 19:02:07.347978	230
2021	2019-12-22 19:02:07.347978	215
2022	2019-12-22 19:02:07.347978	250
2023	2019-12-22 19:02:07.347978	212
2024	2019-12-22 19:02:07.347978	274
2025	2019-12-22 19:02:07.347978	308
2026	2019-12-22 19:02:07.347978	292
2027	2019-12-22 19:02:07.347978	336
2028	2019-12-22 19:02:07.347978	588
2029	2019-12-22 19:02:07.347978	304
2030	2019-12-22 19:02:07.347978	278
2031	2019-12-22 19:02:07.347978	259
2032	2019-12-22 19:02:07.347978	323
2033	2019-12-22 19:02:07.347978	508
2034	2019-12-22 19:02:07.347978	525
2035	2019-12-22 19:02:07.347978	0
2036	2019-12-22 19:02:07.347978	0
2037	2019-12-22 19:02:07.347978	0
2038	2019-12-22 19:02:07.347978	0
2039	2019-12-22 19:02:07.347978	0
2040	2019-12-22 19:02:07.347978	0
2041	2019-12-22 19:02:07.347978	0
2042	2019-12-22 19:02:07.347978	0
2043	2019-12-22 19:02:07.347978	0
2044	2019-12-22 19:02:07.347978	0
2045	2019-12-22 19:02:07.347978	0
2046	2019-12-22 19:02:07.347978	275
2047	2019-12-22 19:02:07.347978	122
2048	2019-12-22 19:02:07.347978	164
2049	2019-12-22 19:02:07.347978	160
2050	2019-12-22 19:02:07.347978	386
2051	2019-12-22 19:02:07.347978	208
2052	2019-12-22 19:02:07.347978	328
2053	2019-12-22 19:02:07.347978	184
2054	2019-12-22 19:02:07.347978	199
2055	2019-12-22 19:02:07.347978	276
2056	2019-12-22 19:02:07.347978	293
2057	2019-12-22 19:02:07.347978	108
2058	2019-12-22 19:02:07.347978	267
2059	2019-12-22 19:02:07.347978	134
2060	2019-12-22 19:02:07.347978	179
2061	2019-12-22 19:02:07.347978	163
2062	2019-12-22 19:02:07.347978	319
2063	2019-12-22 19:02:07.347978	224
2064	2019-12-22 19:02:07.347978	216
2065	2019-12-22 19:02:07.347978	220
2066	2019-12-22 19:02:07.347978	283
2067	2019-12-22 19:02:07.347978	243
2068	2019-12-22 19:02:07.347978	213
2069	2019-12-22 19:02:07.347978	195
2070	2019-12-22 19:02:07.347978	177
2071	2019-12-22 19:02:07.347978	181
2072	2019-12-22 19:02:07.347978	196
2073	2019-12-22 19:02:07.347978	283
2074	2019-12-22 19:02:07.347978	470
2075	2019-12-22 19:02:07.347978	312
2076	2019-12-22 19:02:07.347978	239
2077	2019-12-22 19:02:07.347978	238
2078	2019-12-22 19:02:07.347978	255
2079	2019-12-22 19:02:07.347978	136
2080	2019-12-22 19:02:07.347978	230
2081	2019-12-22 19:02:07.347978	255
2082	2019-12-22 19:02:07.347978	652
2083	2019-12-22 19:02:07.347978	77
2084	2019-12-22 19:02:07.347978	383
2085	2019-12-22 19:02:07.347978	105
2086	2019-12-22 19:02:07.347978	395
2087	2019-12-22 19:02:07.347978	110
2088	2019-12-22 19:02:07.347978	348
2089	2019-12-22 19:02:07.347978	307
2090	2019-12-22 19:02:07.347978	59
2091	2019-12-22 19:02:07.347978	95
2092	2019-12-22 19:02:07.347978	151
2093	2019-12-22 19:02:07.347978	399
2094	2019-12-22 19:02:07.347978	358
2095	2019-12-22 19:02:07.347978	91
2096	2019-12-22 19:02:07.347978	367
2097	2019-12-22 19:02:07.347978	187
2098	2019-12-22 19:02:07.347978	265
2099	2019-12-22 19:02:07.347978	74
2100	2019-12-22 19:02:07.347978	201
2101	2019-12-22 19:02:07.347978	186
2102	2019-12-22 19:02:07.347978	356
2103	2019-12-22 19:02:07.347978	271
2104	2019-12-22 19:02:07.347978	312
2105	2019-12-22 19:02:07.347978	286
2106	2019-12-22 19:02:07.347978	192
2107	2019-12-22 19:02:07.347978	353
2108	2019-12-22 19:02:07.347978	211
2109	2019-12-22 19:02:07.347978	57
2110	2019-12-22 19:02:07.347978	359
2111	2019-12-22 19:02:07.347978	320
2112	2019-12-22 19:02:07.347978	429
2113	2019-12-22 19:02:07.347978	204
2114	2019-12-22 19:02:07.347978	127
2115	2019-12-22 19:02:07.347978	125
2116	2019-12-22 19:02:07.347978	151
2117	2019-12-22 19:02:07.347978	189
2118	2019-12-22 19:02:07.347978	160
2119	2019-12-22 19:02:07.347978	137
2120	2019-12-22 19:02:07.347978	148
2121	2019-12-22 19:02:07.347978	665
2122	2019-12-22 19:02:07.347978	213
2123	2019-12-22 19:02:07.347978	0
2124	2019-12-22 19:02:07.347978	0
2125	2019-12-22 19:02:07.347978	0
2126	2019-12-22 19:02:07.347978	0
2127	2019-12-22 19:02:07.347978	0
2128	2019-12-22 19:02:07.347978	0
2129	2019-12-22 19:02:07.347978	0
2130	2019-12-22 19:02:07.347978	0
2131	2019-12-22 19:02:07.347978	0
2132	2019-12-22 19:02:07.347978	0
2133	2019-12-22 19:02:07.347978	0
2134	2019-12-22 19:02:07.347978	224
2135	2019-12-22 19:02:07.347978	199
2136	2019-12-22 19:02:07.347978	227
2137	2019-12-22 19:02:07.347978	194
2138	2019-12-22 19:02:07.347978	239
2139	2019-12-22 19:02:07.347978	228
2140	2019-12-22 19:02:07.347978	185
2141	2019-12-22 19:02:07.347978	144
2142	2019-12-22 19:02:07.347978	159
2143	2019-12-22 19:02:07.347978	266
2144	2019-12-22 19:02:07.347978	346
2145	2019-12-22 19:02:07.347978	285
2146	2019-12-22 19:02:07.347978	386
2147	2019-12-22 19:02:07.347978	259
2148	2019-12-22 19:02:07.347978	270
2149	2019-12-22 19:02:07.347978	200
2150	2019-12-22 19:02:07.347978	282
2151	2019-12-22 19:02:07.347978	360
2152	2019-12-22 19:02:07.347978	315
2153	2019-12-22 19:02:07.347978	448
2154	2019-12-22 19:02:07.347978	261
2155	2019-12-22 19:02:07.347978	210
2156	2019-12-22 19:02:07.347978	287
2157	2019-12-22 19:02:07.347978	252
2158	2019-12-22 19:02:07.347978	316
2159	2019-12-22 19:02:07.347978	367
2160	2019-12-22 19:02:07.347978	562
2161	2019-12-22 19:02:07.347978	503
2162	2019-12-22 19:02:07.347978	429
2163	2019-12-22 19:02:07.347978	390
2164	2019-12-22 19:02:07.347978	121
2165	2019-12-22 19:02:07.347978	180
2166	2019-12-22 19:02:07.347978	204
2167	2019-12-22 19:02:07.347978	190
2168	2019-12-22 19:02:07.347978	276
2169	2019-12-22 19:02:07.347978	182
2170	2019-12-22 19:02:07.347978	231
2171	2019-12-22 19:02:07.347978	185
2172	2019-12-22 19:02:07.347978	187
2173	2019-12-22 19:02:07.347978	386
2174	2019-12-22 19:02:07.347978	213
2175	2019-12-22 19:02:07.347978	0
2176	2019-12-22 19:02:07.347978	0
2177	2019-12-22 19:02:07.347978	0
2178	2019-12-22 19:02:07.347978	0
2179	2019-12-22 19:02:07.347978	0
2180	2019-12-22 19:02:07.347978	0
2181	2019-12-22 19:02:07.347978	0
2182	2019-12-22 19:02:07.347978	0
2183	2019-12-22 19:02:07.347978	0
2184	2019-12-22 19:02:07.347978	0
2185	2019-12-22 19:02:07.347978	0
2186	2019-12-22 19:02:07.347978	0
2187	2019-12-22 19:02:07.347978	0
2188	2019-12-22 19:02:07.347978	0
2189	2019-12-22 19:02:07.347978	0
2190	2019-12-22 19:02:07.347978	0
2191	2019-12-22 19:02:07.347978	0
2192	2019-12-22 19:02:07.347978	0
2193	2019-12-22 19:02:07.347978	0
2194	2019-12-22 19:02:07.347978	0
2195	2019-12-22 19:02:07.347978	0
2196	2019-12-22 19:02:07.347978	0
2197	2019-12-22 19:02:07.347978	0
2198	2019-12-22 19:02:07.347978	0
2199	2019-12-22 19:02:07.347978	0
2200	2019-12-22 19:02:07.347978	0
2201	2019-12-22 19:02:07.347978	0
2202	2019-12-22 19:02:07.347978	0
2203	2019-12-22 19:02:07.347978	0
2204	2019-12-22 19:02:07.347978	0
2205	2019-12-22 19:02:07.347978	0
2206	2019-12-22 19:02:07.347978	0
2207	2019-12-22 19:02:07.347978	0
2208	2019-12-22 19:02:07.347978	0
2209	2019-12-22 19:02:07.347978	0
2210	2019-12-22 19:02:07.347978	239
2211	2019-12-22 19:02:07.347978	288
2212	2019-12-22 19:02:07.347978	193
2213	2019-12-22 19:02:07.347978	162
2214	2019-12-22 19:02:07.347978	334
2215	2019-12-22 19:02:07.347978	279
2216	2019-12-22 19:02:07.347978	214
2217	2019-12-22 19:02:07.347978	225
2218	2019-12-22 19:02:07.347978	257
2219	2019-12-22 19:02:07.347978	171
2220	2019-12-22 19:02:07.347978	195
2221	2019-12-22 19:02:07.347978	860
2222	2019-12-22 19:02:07.347978	420
2223	2019-12-22 19:02:07.347978	350
2224	2019-12-22 19:02:07.347978	375
2225	2019-12-22 19:02:07.347978	475
2226	2019-12-22 19:02:07.347978	0
2227	2019-12-22 19:02:07.347978	0
2228	2019-12-22 19:02:07.347978	0
2229	2019-12-22 19:02:07.347978	0
2230	2019-12-22 19:02:07.347978	0
2231	2019-12-22 19:02:07.347978	0
2232	2019-12-22 19:02:07.347978	0
2233	2019-12-22 19:02:07.347978	0
2234	2019-12-22 19:02:07.347978	0
2235	2019-12-22 19:02:07.347978	0
2236	2019-12-22 19:02:07.347978	0
2237	2019-12-22 19:02:07.347978	314
2238	2019-12-22 19:02:07.347978	281
2239	2019-12-22 19:02:07.347978	267
2240	2019-12-22 19:02:07.347978	189
2241	2019-12-22 19:02:07.347978	301
2242	2019-12-22 19:02:07.347978	288
2243	2019-12-22 19:02:07.347978	290
2244	2019-12-22 19:02:07.347978	319
2245	2019-12-22 19:02:07.347978	314
2246	2019-12-22 19:02:07.347978	280
2247	2019-12-22 19:02:07.347978	267
2248	2019-12-22 19:02:07.347978	192
2249	2019-12-22 19:02:07.347978	300
2250	2019-12-22 19:02:07.347978	286
2251	2019-12-22 19:02:07.347978	290
2252	2019-12-22 19:02:07.347978	321
2253	2019-12-22 19:02:07.347978	170
2254	2019-12-22 19:02:07.347978	279
2255	2019-12-22 19:02:07.347978	335
2256	2019-12-22 19:02:07.347978	370
2257	2019-12-22 19:02:07.347978	258
2258	2019-12-22 19:02:07.347978	267
2259	2019-12-22 19:02:07.347978	183
2260	2019-12-22 19:02:07.347978	295
2261	2019-12-22 19:02:07.347978	172
2262	2019-12-22 19:02:07.347978	227
2263	2019-12-22 19:02:07.347978	183
2264	2019-12-22 19:02:07.347978	227
2265	2019-12-22 19:02:07.347978	164
2266	2019-12-22 19:02:07.347978	226
2267	2019-12-22 19:02:07.347978	294
2268	2019-12-22 19:02:07.347978	215
2269	2019-12-22 19:02:07.347978	286
2270	2019-12-22 19:02:07.347978	346
2271	2019-12-22 19:02:07.347978	0
2272	2019-12-22 19:02:07.347978	667
2273	2019-12-22 19:02:07.347978	49
2274	2019-12-22 19:02:07.347978	195
2275	2019-12-22 19:02:07.347978	419
2276	2019-12-22 19:02:07.347978	326
2277	2019-12-22 19:02:07.347978	280
2278	2019-12-22 19:02:07.347978	207
2279	2019-12-22 19:02:07.347978	242
2280	2019-12-22 19:02:07.347978	218
2281	2019-12-22 19:02:07.347978	265
2282	2019-12-22 19:02:07.347978	280
2283	2019-12-22 19:02:07.347978	222
2284	2019-12-22 19:02:07.347978	184
2285	2019-12-22 19:02:07.347978	195
2286	2019-12-22 19:02:07.347978	125
2287	2019-12-22 19:02:07.347978	135
2288	2019-12-22 19:02:07.347978	135
2289	2019-12-22 19:02:07.347978	167
2290	2019-12-22 19:02:07.347978	147
2291	2019-12-22 19:02:07.347978	125
2292	2019-12-22 19:02:07.347978	110
2293	2019-12-22 19:02:07.347978	131
2294	2019-12-22 19:02:07.347978	110
2295	2019-12-22 19:02:07.347978	136
2296	2019-12-22 19:02:07.347978	134
2297	2019-12-22 19:02:07.347978	145
2298	2019-12-22 19:02:07.347978	140
2299	2019-12-22 19:02:07.347978	141
2300	2019-12-22 19:02:07.347978	165
2301	2019-12-22 19:02:07.347978	157
2302	2019-12-22 19:02:07.347978	137
2303	2019-12-22 19:02:07.347978	188
2304	2019-12-22 19:02:07.347978	134
2305	2019-12-22 19:02:07.347978	125
2306	2019-12-22 19:02:07.347978	168
2307	2019-12-22 19:02:07.347978	189
2308	2019-12-22 19:02:07.347978	184
2309	2019-12-22 19:02:07.347978	235
2310	2019-12-22 19:02:07.347978	101
2311	2019-12-22 19:02:07.347978	287
2312	2019-12-22 19:02:07.347978	246
2313	2019-12-22 19:02:07.347978	180
2314	2019-12-22 19:02:07.347978	199
2315	2019-12-22 19:02:07.347978	259
2316	2019-12-22 19:02:07.347978	269
2317	2019-12-22 19:02:07.347978	417
2318	2019-12-22 19:02:07.347978	209
2319	2019-12-22 19:02:07.347978	308
2320	2019-12-22 19:02:07.347978	227
2321	2019-12-22 19:02:07.347978	230
2322	2019-12-22 19:02:07.347978	283
2323	2019-12-22 19:02:07.347978	188
2324	2019-12-22 19:02:07.347978	235
2325	2019-12-22 19:02:07.347978	240
2326	2019-12-22 19:02:07.347978	315
2327	2019-12-22 19:02:07.347978	442
2328	2019-12-22 19:02:07.347978	418
2329	2019-12-22 19:02:07.347978	210
2330	2019-12-22 19:02:07.347978	309
2331	2019-12-22 19:02:07.347978	229
2332	2019-12-22 19:02:07.347978	232
2333	2019-12-22 19:02:07.347978	284
2334	2019-12-22 19:02:07.347978	189
2335	2019-12-22 19:02:07.347978	236
2336	2019-12-22 19:02:07.347978	241
2337	2019-12-22 19:02:07.347978	318
2338	2019-12-22 19:02:07.347978	443
2339	2019-12-22 19:02:07.347978	941
2340	2019-12-22 19:02:07.347978	389
2341	2019-12-22 19:02:07.347978	618
2342	2019-12-22 19:02:07.347978	550
2343	2019-12-22 19:02:07.347978	212
2344	2019-12-22 19:02:07.347978	102
2345	2019-12-22 19:02:07.347978	157
2346	2019-12-22 19:02:07.347978	227
2347	2019-12-22 19:02:07.347978	224
2348	2019-12-22 19:02:07.347978	210
2349	2019-12-22 19:02:07.347978	180
2350	2019-12-22 19:02:07.347978	220
2351	2019-12-22 19:02:07.347978	202
2352	2019-12-22 19:02:07.347978	198
2353	2019-12-22 19:02:07.347978	181
2354	2019-12-22 19:02:07.347978	230
2355	2019-12-22 19:02:07.347978	301
2356	2019-12-22 19:02:07.347978	282
2357	2019-12-22 19:02:07.347978	252
2358	2019-12-22 19:02:07.347978	301
2359	2019-12-22 19:02:07.347978	218
2360	2019-12-22 19:02:07.347978	308
2361	2019-12-22 19:02:07.347978	390
2362	2019-12-22 19:02:07.347978	0
2363	2019-12-22 19:02:07.347978	0
2364	2019-12-22 19:02:07.347978	0
2365	2019-12-22 19:02:07.347978	0
2366	2019-12-22 19:02:07.347978	0
2367	2019-12-22 19:02:07.347978	0
2368	2019-12-22 19:02:07.347978	0
2369	2019-12-22 19:02:07.347978	0
2370	2019-12-22 19:02:07.347978	0
2371	2019-12-22 19:02:07.347978	0
2372	2019-12-22 19:02:07.347978	0
2373	2019-12-22 19:02:07.347978	0
2374	2019-12-22 19:02:07.347978	0
2375	2019-12-22 19:02:07.347978	0
2376	2019-12-22 19:02:07.347978	0
2377	2019-12-22 19:02:07.347978	0
2378	2019-12-22 19:02:07.347978	0
2379	2019-12-22 19:02:07.347978	0
2380	2019-12-22 19:02:07.347978	0
2381	2019-12-22 19:02:07.347978	0
2382	2019-12-22 19:02:07.347978	0
2383	2019-12-22 19:02:07.347978	138
2384	2019-12-22 19:02:07.347978	118
2385	2019-12-22 19:02:07.347978	116
2386	2019-12-22 19:02:07.347978	139
2387	2019-12-22 19:02:07.347978	143
2388	2019-12-22 19:02:07.347978	124
2389	2019-12-22 19:02:07.347978	130
2390	2019-12-22 19:02:07.347978	149
2391	2019-12-22 19:02:07.347978	148
2392	2019-12-22 19:02:07.347978	162
2393	2019-12-22 19:02:07.347978	140
2394	2019-12-22 19:02:07.347978	183
2395	2019-12-22 19:02:07.347978	124
2396	2019-12-22 19:02:07.347978	153
2397	2019-12-22 19:02:07.347978	126
2398	2019-12-22 19:02:07.347978	132
2399	2019-12-22 19:02:07.347978	168
2400	2019-12-22 19:02:07.347978	147
2401	2019-12-22 19:02:07.347978	122
2402	2019-12-22 19:02:07.347978	160
2403	2019-12-22 19:02:07.347978	161
2404	2019-12-22 19:02:07.347978	142
2405	2019-12-22 19:02:07.347978	147
2406	2019-12-22 19:02:07.347978	135
2407	2019-12-22 19:02:07.347978	123
2408	2019-12-22 19:02:07.347978	166
2409	2019-12-22 19:02:07.347978	97
2410	2019-12-22 19:02:07.347978	94
2411	2019-12-22 19:02:07.347978	135
2412	2019-12-22 19:02:07.347978	156
2413	2019-12-22 19:02:07.347978	60
2414	2019-12-22 19:02:07.347978	152
2415	2019-12-22 19:02:07.347978	163
2416	2019-12-22 19:02:07.347978	322
2417	2019-12-22 19:02:07.347978	236
2418	2019-12-22 19:02:07.347978	138
2419	2019-12-22 19:02:07.347978	199
2420	2019-12-22 19:02:07.347978	160
2421	2019-12-22 19:02:07.347978	0
2422	2019-12-22 19:02:07.347978	271
2423	2019-12-22 19:02:07.347978	201
2424	2019-12-22 19:02:07.347978	266
2425	2019-12-22 19:02:07.347978	260
2426	2019-12-22 19:02:07.347978	226
2427	2019-12-22 19:02:07.347978	406
2428	2019-12-22 19:02:07.347978	0
2429	2019-12-22 19:02:07.347978	219
2430	2019-12-22 19:02:07.347978	230
2431	2019-12-22 19:02:07.347978	355
2432	2019-12-22 19:02:07.347978	195
2433	2019-12-22 19:02:07.347978	205
2434	2019-12-22 19:02:07.347978	373
2435	2019-12-22 19:02:07.347978	209
2436	2019-12-22 19:02:07.347978	250
2437	2019-12-22 19:02:07.347978	381
2438	2019-12-22 19:02:07.347978	253
2439	2019-12-22 19:02:07.347978	213
2440	2019-12-22 19:02:07.347978	291
2441	2019-12-22 19:02:07.347978	172
2442	2019-12-22 19:02:07.347978	288
2443	2019-12-22 19:02:07.347978	256
2444	2019-12-22 19:02:07.347978	275
2445	2019-12-22 19:02:07.347978	217
2446	2019-12-22 19:02:07.347978	218
2447	2019-12-22 19:02:07.347978	221
2448	2019-12-22 19:02:07.347978	230
2449	2019-12-22 19:02:07.347978	236
2450	2019-12-22 19:02:07.347978	186
2451	2019-12-22 19:02:07.347978	218
2452	2019-12-22 19:02:07.347978	241
2453	2019-12-22 19:02:07.347978	217
2454	2019-12-22 19:02:07.347978	246
2455	2019-12-22 19:02:07.347978	227
2456	2019-12-22 19:02:07.347978	160
2457	2019-12-22 19:02:07.347978	140
2458	2019-12-22 19:02:07.347978	177
2459	2019-12-22 19:02:07.347978	184
2460	2019-12-22 19:02:07.347978	270
2461	2019-12-22 19:02:07.347978	240
2462	2019-12-22 19:02:07.347978	187
2463	2019-12-22 19:02:07.347978	292
2464	2019-12-22 19:02:07.347978	131
2465	2019-12-22 19:02:07.347978	205
2466	2019-12-22 19:02:07.347978	240
2467	2019-12-22 19:02:07.347978	161
2468	2019-12-22 19:02:07.347978	231
2469	2019-12-22 19:02:07.347978	241
2470	2019-12-22 19:02:07.347978	272
2471	2019-12-22 19:02:07.347978	312
2472	2019-12-22 19:02:07.347978	165
2473	2019-12-22 19:02:07.347978	412
2474	2019-12-22 19:02:07.347978	264
2475	2019-12-22 19:02:07.347978	137
2476	2019-12-22 19:02:07.347978	243
2477	2019-12-22 19:02:07.347978	237
2478	2019-12-22 19:02:07.347978	268
2479	2019-12-22 19:02:07.347978	235
2480	2019-12-22 19:02:07.347978	323
2481	2019-12-22 19:02:07.347978	198
2482	2019-12-22 19:02:07.347978	250
2483	2019-12-22 19:02:07.347978	178
2484	2019-12-22 19:02:07.347978	347
2485	2019-12-22 19:02:07.347978	376
2486	2019-12-22 19:02:07.347978	282
2487	2019-12-22 19:02:07.347978	305
2488	2019-12-22 19:02:07.347978	231
2489	2019-12-22 19:02:07.347978	183
2490	2019-12-22 19:02:07.347978	223
2491	2019-12-22 19:02:07.347978	166
2492	2019-12-22 19:02:07.347978	178
2493	2019-12-22 19:02:07.347978	200
2494	2019-12-22 19:02:07.347978	219
2495	2019-12-22 19:02:07.347978	439
2496	2019-12-22 19:02:07.347978	212
2497	2019-12-22 19:02:07.347978	249
2498	2019-12-22 19:02:07.347978	108
2499	2019-12-22 19:02:07.347978	220
2500	2019-12-22 19:02:07.347978	197
2501	2019-12-22 19:02:07.347978	162
2502	2019-12-22 19:02:07.347978	0
2503	2019-12-22 19:02:07.347978	0
2504	2019-12-22 19:02:07.347978	0
2505	2019-12-22 19:02:07.347978	0
2506	2019-12-22 19:02:07.347978	0
2507	2019-12-22 19:02:07.347978	0
2508	2019-12-22 19:02:07.347978	0
2509	2019-12-22 19:02:07.347978	0
2510	2019-12-22 19:02:07.347978	0
2511	2019-12-22 19:02:07.347978	0
2512	2019-12-22 19:02:07.347978	0
2513	2019-12-22 19:02:07.347978	0
2514	2019-12-22 19:02:07.347978	0
2515	2019-12-22 19:02:07.347978	0
2516	2019-12-22 19:02:07.347978	0
2517	2019-12-22 19:02:07.347978	142
2518	2019-12-22 19:02:07.347978	186
2519	2019-12-22 19:02:07.347978	234
2520	2019-12-22 19:02:07.347978	200
2521	2019-12-22 19:02:07.347978	112
2522	2019-12-22 19:02:07.347978	190
2523	2019-12-22 19:02:07.347978	178
2524	2019-12-22 19:02:07.347978	170
2525	2019-12-22 19:02:07.347978	140
2526	2019-12-22 19:02:07.347978	155
2527	2019-12-22 19:02:07.347978	262
2528	2019-12-22 19:02:07.347978	322
2529	2019-12-22 19:02:07.347978	341
2530	2019-12-22 19:02:07.347978	314
2531	2019-12-22 19:02:07.347978	270
2532	2019-12-22 19:02:07.347978	346
2533	2019-12-22 19:02:07.347978	314
2534	2019-12-22 19:02:07.347978	271
2535	2019-12-22 19:02:07.347978	233
2536	2019-12-22 19:02:07.347978	252
2537	2019-12-22 19:02:07.347978	263
2538	2019-12-22 19:02:07.347978	359
2539	2019-12-22 19:02:07.347978	0
2540	2019-12-22 19:02:07.347978	0
2541	2019-12-22 19:02:07.347978	0
2542	2019-12-22 19:02:07.347978	0
2543	2019-12-22 19:02:07.347978	0
2544	2019-12-22 19:02:07.347978	0
2545	2019-12-22 19:02:07.347978	0
2546	2019-12-22 19:02:07.347978	0
2547	2019-12-22 19:02:07.347978	0
2548	2019-12-22 19:02:07.347978	0
2549	2019-12-22 19:02:07.347978	0
2550	2019-12-22 19:02:07.347978	0
2551	2019-12-22 19:02:07.347978	0
2552	2019-12-22 19:02:07.347978	0
2553	2019-12-22 19:02:07.347978	0
2554	2019-12-22 19:02:07.347978	0
2555	2019-12-22 19:02:07.347978	0
2556	2019-12-22 19:02:07.347978	0
2557	2019-12-22 19:02:07.347978	0
2558	2019-12-22 19:02:07.347978	0
2559	2019-12-22 19:02:07.347978	0
2560	2019-12-22 19:02:07.347978	0
2561	2019-12-22 19:02:07.347978	0
2562	2019-12-22 19:02:07.347978	0
2563	2019-12-22 19:02:07.347978	0
2564	2019-12-22 19:02:07.347978	115
2565	2019-12-22 19:02:07.347978	175
2566	2019-12-22 19:02:07.347978	180
2567	2019-12-22 19:02:07.347978	180
2568	2019-12-22 19:02:07.347978	106
2569	2019-12-22 19:02:07.347978	144
2570	2019-12-22 19:02:07.347978	332
2571	2019-12-22 19:02:07.347978	165
2572	2019-12-22 19:02:07.347978	166
2573	2019-12-22 19:02:07.347978	157
2574	2019-12-22 19:02:07.347978	220
2575	2019-12-22 19:02:07.347978	140
2576	2019-12-22 19:02:07.347978	249
2577	2019-12-22 19:02:07.347978	335
2578	2019-12-22 19:02:07.347978	309
2579	2019-12-22 19:02:07.347978	387
2580	2019-12-22 19:02:07.347978	290
2581	2019-12-22 19:02:07.347978	326
2582	2019-12-22 19:02:07.347978	378
2583	2019-12-22 19:02:07.347978	265
2584	2019-12-22 19:02:07.347978	198
2585	2019-12-22 19:02:07.347978	290
2586	2019-12-22 19:02:07.347978	258
2587	2019-12-22 19:02:07.347978	265
2588	2019-12-22 19:02:07.347978	280
2589	2019-12-22 19:02:07.347978	192
2590	2019-12-22 19:02:07.347978	264
2591	2019-12-22 19:02:07.347978	185
2592	2019-12-22 19:02:07.347978	206
2593	2019-12-22 19:02:07.347978	264
2594	2019-12-22 19:02:07.347978	223
2595	2019-12-22 19:02:07.347978	366
2596	2019-12-22 19:02:07.347978	199
2597	2019-12-22 19:02:07.347978	245
2598	2019-12-22 19:02:07.347978	230
2599	2019-12-22 19:02:07.347978	261
2600	2019-12-22 19:02:07.347978	321
2601	2019-12-22 19:02:07.347978	215
2602	2019-12-22 19:02:07.347978	223
2603	2019-12-22 19:02:07.347978	185
2604	2019-12-22 19:02:07.347978	217
2605	2019-12-22 19:02:07.347978	129
2606	2019-12-22 19:02:07.347978	222
2607	2019-12-22 19:02:07.347978	153
2608	2019-12-22 19:02:07.347978	163
2609	2019-12-22 19:02:07.347978	403
2610	2019-12-22 19:02:07.347978	166
2611	2019-12-22 19:02:07.347978	194
2612	2019-12-22 19:02:07.347978	234
2613	2019-12-22 19:02:07.347978	214
2614	2019-12-22 19:02:07.347978	220
2615	2019-12-22 19:02:07.347978	258
2616	2019-12-22 19:02:07.347978	242
2617	2019-12-22 19:02:07.347978	165
2618	2019-12-22 19:02:07.347978	182
2619	2019-12-22 19:02:07.347978	351
2620	2019-12-22 19:02:07.347978	110
2621	2019-12-22 19:02:07.347978	170
2622	2019-12-22 19:02:07.347978	169
2623	2019-12-22 19:02:07.347978	135
2624	2019-12-22 19:02:07.347978	225
2625	2019-12-22 19:02:07.347978	165
2626	2019-12-22 19:02:07.347978	172
2627	2019-12-22 19:02:07.347978	160
2628	2019-12-22 19:02:07.347978	232
2629	2019-12-22 19:02:07.347978	200
2630	2019-12-22 19:02:07.347978	200
2631	2019-12-22 19:02:07.347978	192
2632	2019-12-22 19:02:07.347978	209
2633	2019-12-22 19:02:07.347978	220
2634	2019-12-22 19:02:07.347978	190
2635	2019-12-22 19:02:07.347978	374
2636	2019-12-22 19:02:07.347978	183
2637	2019-12-22 19:02:07.347978	270
2638	2019-12-22 19:02:07.347978	503
2639	2019-12-22 19:02:07.347978	448
2640	2019-12-22 19:02:07.347978	230
2641	2019-12-22 19:02:07.347978	341
2642	2019-12-22 19:02:07.347978	298
2643	2019-12-22 19:02:07.347978	220
2644	2019-12-22 19:02:07.347978	354
2645	2019-12-22 19:02:07.347978	278
2646	2019-12-22 19:02:07.347978	205
2647	2019-12-22 19:02:07.347978	380
2648	2019-12-22 19:02:07.347978	320
2649	2019-12-22 19:02:07.347978	283
2650	2019-12-22 19:02:07.347978	327
2651	2019-12-22 19:02:07.347978	244
2652	2019-12-22 19:02:07.347978	220
2653	2019-12-22 19:02:07.347978	229
2654	2019-12-22 19:02:07.347978	396
2655	2019-12-22 19:02:07.347978	229
2656	2019-12-22 19:02:07.347978	259
2657	2019-12-22 19:02:07.347978	269
2658	2019-12-22 19:02:07.347978	470
2659	2019-12-22 19:02:07.347978	248
2660	2019-12-22 19:02:07.347978	0
2661	2019-12-22 19:02:07.347978	0
2662	2019-12-22 19:02:07.347978	0
2663	2019-12-22 19:02:07.347978	0
2664	2019-12-22 19:02:07.347978	0
2665	2019-12-22 19:02:07.347978	0
2666	2019-12-22 19:02:07.347978	0
2667	2019-12-22 19:02:07.347978	0
2668	2019-12-22 19:02:07.347978	0
2669	2019-12-22 19:02:07.347978	0
2670	2019-12-22 19:02:07.347978	0
2671	2019-12-22 19:02:07.347978	0
2672	2019-12-22 19:02:07.347978	0
2673	2019-12-22 19:02:07.347978	326
2674	2019-12-22 19:02:07.347978	226
2675	2019-12-22 19:02:07.347978	255
2676	2019-12-22 19:02:07.347978	295
2677	2019-12-22 19:02:07.347978	150
2678	2019-12-22 19:02:07.347978	131
2679	2019-12-22 19:02:07.347978	367
2680	2019-12-22 19:02:07.347978	255
2681	2019-12-22 19:02:07.347978	384
2682	2019-12-22 19:02:07.347978	150
2683	2019-12-22 19:02:07.347978	228
2684	2019-12-22 19:02:07.347978	222
2685	2019-12-22 19:02:07.347978	195
2686	2019-12-22 19:02:07.347978	219
2687	2019-12-22 19:02:07.347978	210
2688	2019-12-22 19:02:07.347978	111
2689	2019-12-22 19:02:07.347978	187
2690	2019-12-22 19:02:07.347978	203
2691	2019-12-22 19:02:07.347978	307
2692	2019-12-22 19:02:07.347978	216
2693	2019-12-22 19:02:07.347978	60
2694	2019-12-22 19:02:07.347978	290
2695	2019-12-22 19:02:07.347978	191
2696	2019-12-22 19:02:07.347978	181
2697	2019-12-22 19:02:07.347978	389
2698	2019-12-22 19:02:07.347978	270
2699	2019-12-22 19:02:07.347978	270
2700	2019-12-22 19:02:07.347978	196
2701	2019-12-22 19:02:07.347978	573
2702	2019-12-22 19:02:07.347978	250
2703	2019-12-22 19:02:07.347978	184
2704	2019-12-22 19:02:07.347978	303
2705	2019-12-22 19:02:07.347978	212
2706	2019-12-22 19:02:07.347978	150
2707	2019-12-22 19:02:07.347978	196
2708	2019-12-22 19:02:07.347978	182
2709	2019-12-22 19:02:07.347978	205
2710	2019-12-22 19:02:07.347978	147
2711	2019-12-22 19:02:07.347978	196
2712	2019-12-22 19:02:07.347978	187
2713	2019-12-22 19:02:07.347978	139
2714	2019-12-22 19:02:07.347978	244
2715	2019-12-22 19:02:07.347978	272
2716	2019-12-22 19:02:07.347978	182
2717	2019-12-22 19:02:07.347978	273
2718	2019-12-22 19:02:07.347978	364
2719	2019-12-22 19:02:07.347978	254
2720	2019-12-22 19:02:07.347978	268
2721	2019-12-22 19:02:07.347978	235
2722	2019-12-22 19:02:07.347978	220
2723	2019-12-22 19:02:07.347978	348
2724	2019-12-22 19:02:07.347978	127
2725	2019-12-22 19:02:07.347978	165
2726	2019-12-22 19:02:07.347978	174
2727	2019-12-22 19:02:07.347978	239
2728	2019-12-22 19:02:07.347978	225
2729	2019-12-22 19:02:07.347978	151
2730	2019-12-22 19:02:07.347978	181
2731	2019-12-22 19:02:07.347978	134
2732	2019-12-22 19:02:07.347978	158
2733	2019-12-22 19:02:07.347978	178
2734	2019-12-22 19:02:07.347978	95
2735	2019-12-22 19:02:07.347978	104
2736	2019-12-22 19:02:07.347978	106
2737	2019-12-22 19:02:07.347978	169
2738	2019-12-22 19:02:07.347978	0
\.


--
-- Data for Name: tracks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tracks (id, created_at, name, album_id, disc_id, position_id, artist_id, mediafile_id, specs) FROM stdin;
1	2019-12-22 19:02:07.347978	Give Life Back To Music	15	1	1	15	5	{}
2	2019-12-22 19:02:07.347978	The Game Of Love	15	1	2	15	6	{}
3	2019-12-22 19:02:07.347978	Giorgio By Moroder	15	1	3	15	7	{}
4	2019-12-22 19:02:07.347978	Within	15	2	1	15	8	{}
5	2019-12-22 19:02:07.347978	Instant Crush	15	2	2	15	9	{}
6	2019-12-22 19:02:07.347978	Lose Yourself To Dance	15	2	3	15	10	{}
7	2019-12-22 19:02:07.347978	Touch	15	3	1	15	11	{}
8	2019-12-22 19:02:07.347978	Get Lucky	15	3	2	15	12	{}
9	2019-12-22 19:02:07.347978	Beyond	15	3	3	15	13	{}
10	2019-12-22 19:02:07.347978	Motherboard	15	4	1	15	14	{}
11	2019-12-22 19:02:07.347978	Fragments Of Time	15	4	2	15	15	{}
12	2019-12-22 19:02:07.347978	Doin' It Right	15	4	3	15	16	{}
13	2019-12-22 19:02:07.347978	Contact	15	4	4	15	17	{}
14	2019-12-22 19:02:07.347978	Second Hand News	36	1	1	34	18	{}
15	2019-12-22 19:02:07.347978	Dreams	36	1	2	34	19	{}
16	2019-12-22 19:02:07.347978	Never Going Back Again	36	1	3	34	20	{}
17	2019-12-22 19:02:07.347978	Don't Stop	36	1	4	34	21	{}
18	2019-12-22 19:02:07.347978	Go Your Own Way	36	1	5	34	22	{}
19	2019-12-22 19:02:07.347978	Songbird	36	1	6	34	23	{}
20	2019-12-22 19:02:07.347978	The Chain	36	2	1	34	24	{}
21	2019-12-22 19:02:07.347978	You Make Loving Fun	36	2	2	34	25	{}
22	2019-12-22 19:02:07.347978	I Don't Want To Know	36	2	3	34	26	{}
23	2019-12-22 19:02:07.347978	Oh Daddy	36	2	4	34	27	{}
24	2019-12-22 19:02:07.347978	Gold Dust Woman	36	2	5	34	28	{}
25	2019-12-22 19:02:07.347978	Speak To Me	130	1	1	127	29	{}
26	2019-12-22 19:02:07.347978	Breathe	130	1	2	127	30	{}
27	2019-12-22 19:02:07.347978	On The Run	130	1	3	127	31	{}
28	2019-12-22 19:02:07.347978	Time	130	1	4	127	32	{}
29	2019-12-22 19:02:07.347978	The Great Gig In The Sky	130	1	5	127	33	{}
30	2019-12-22 19:02:07.347978	Money	130	2	1	127	34	{}
31	2019-12-22 19:02:07.347978	Us And Them	130	2	2	127	35	{}
32	2019-12-22 19:02:07.347978	Any Colour You Like	130	2	3	127	36	{}
33	2019-12-22 19:02:07.347978	Brain Damage	130	2	4	127	37	{}
34	2019-12-22 19:02:07.347978	Eclipse	130	2	5	127	38	{}
35	2019-12-22 19:02:07.347978	Wanna Be Startin' Somethin'	7	1	1	7	39	{}
36	2019-12-22 19:02:07.347978	Baby Be Mine	7	1	2	7	40	{}
37	2019-12-22 19:02:07.347978	The Girl Is Mine	7	1	3	7	41	{}
38	2019-12-22 19:02:07.347978	Thriller	7	1	4	7	42	{}
39	2019-12-22 19:02:07.347978	Beat It	7	2	1	7	43	{}
40	2019-12-22 19:02:07.347978	Billie Jean	7	2	2	7	44	{}
41	2019-12-22 19:02:07.347978	Human Nature	7	2	3	7	45	{}
42	2019-12-22 19:02:07.347978	P.Y.T. (Pretty Young Thing)	7	2	4	7	46	{}
43	2019-12-22 19:02:07.347978	The Lady In My Life	7	2	5	7	47	{}
44	2019-12-22 19:02:07.347978	Three Women	173	1	1	165	48	{}
45	2019-12-22 19:02:07.347978	Lazaretto	173	1	2	165	49	{}
46	2019-12-22 19:02:07.347978	Temporary Ground	173	1	3	165	50	{}
47	2019-12-22 19:02:07.347978	Would You Fight For My Love?	173	1	4	165	51	{}
48	2019-12-22 19:02:07.347978	High Ball Stepper	173	1	5	165	52	{}
49	2019-12-22 19:02:07.347978	Untitled	173	1	6	165	53	{}
50	2019-12-22 19:02:07.347978	Untitled	173	1	7	165	54	{}
51	2019-12-22 19:02:07.347978	Just One Drink	173	2	1	165	55	{}
52	2019-12-22 19:02:07.347978	Just One Drink	173	2	2	165	56	{}
53	2019-12-22 19:02:07.347978	Alone In My Home	173	2	3	165	57	{}
54	2019-12-22 19:02:07.347978	That Black Bat Licorice	173	2	4	165	58	{}
55	2019-12-22 19:02:07.347978	Entitlement	173	2	5	165	59	{}
56	2019-12-22 19:02:07.347978	I Think I Found The Culprit	173	2	6	165	60	{}
57	2019-12-22 19:02:07.347978	Want And Able	173	2	7	165	61	{}
58	2019-12-22 19:02:07.347978	Untitled	173	2	8	165	62	{}
59	2019-12-22 19:02:07.347978	Untitled	173	2	9	165	63	{}
60	2019-12-22 19:02:07.347978	Let's Go Crazy	17	1	1	16	64	{}
61	2019-12-22 19:02:07.347978	Take Me With U	17	1	2	16	65	{}
62	2019-12-22 19:02:07.347978	The Beautiful Ones	17	1	3	16	66	{}
63	2019-12-22 19:02:07.347978	Computer Blue	17	1	4	16	67	{}
64	2019-12-22 19:02:07.347978	Darling Nikki	17	1	5	16	68	{}
65	2019-12-22 19:02:07.347978	When Doves Cry	17	2	1	16	69	{}
66	2019-12-22 19:02:07.347978	I Would Die 4 U	17	2	2	16	70	{}
67	2019-12-22 19:02:07.347978	Baby I'm A Star	17	2	3	16	71	{}
68	2019-12-22 19:02:07.347978	Purple Rain	17	2	4	16	72	{}
69	2019-12-22 19:02:07.347978	Sherane a.k.a Master Splinter’s Daughter	214	1	1	189	73	{}
70	2019-12-22 19:02:07.347978	Bitch, Don’t Kill My Vibe	214	1	2	189	74	{}
71	2019-12-22 19:02:07.347978	Backseat Freestyle	214	1	3	189	75	{}
72	2019-12-22 19:02:07.347978	The Art Of Peer Pressure	214	1	4	189	76	{}
73	2019-12-22 19:02:07.347978	Money Trees	214	2	1	189	77	{}
74	2019-12-22 19:02:07.347978	Poetic Justice	214	2	2	189	78	{}
75	2019-12-22 19:02:07.347978	Good Kid	214	2	3	189	79	{}
76	2019-12-22 19:02:07.347978	M.A.A.d City	214	2	4	189	80	{}
77	2019-12-22 19:02:07.347978	Swimming Pools (Drank) (Extended Version)	214	3	1	189	81	{}
78	2019-12-22 19:02:07.347978	Sing About Me, I'm Dying Of Thirst	214	3	2	189	82	{}
79	2019-12-22 19:02:07.347978	Real	214	3	3	189	83	{}
80	2019-12-22 19:02:07.347978	Compton	214	4	1	189	84	{}
81	2019-12-22 19:02:07.347978	The Recipe	214	4	2	189	85	{}
82	2019-12-22 19:02:07.347978	Black Boy Fly	214	4	3	189	86	{}
83	2019-12-22 19:02:07.347978	Now Or Never	214	4	4	189	87	{}
84	2019-12-22 19:02:07.347978	Out On The Weekend	153	1	1	147	88	{}
85	2019-12-22 19:02:07.347978	Harvest	153	1	2	147	89	{}
86	2019-12-22 19:02:07.347978	A Man Needs A Maid	153	1	3	147	90	{}
87	2019-12-22 19:02:07.347978	Heart Of Gold	153	1	4	147	91	{}
88	2019-12-22 19:02:07.347978	Are You Ready For The Country	153	1	5	147	92	{}
89	2019-12-22 19:02:07.347978	Old Man	153	2	1	147	93	{}
90	2019-12-22 19:02:07.347978	There's A World	153	2	2	147	94	{}
91	2019-12-22 19:02:07.347978	Alabama	153	2	3	147	95	{}
92	2019-12-22 19:02:07.347978	The Needle And The Damage Done	153	2	4	147	96	{}
93	2019-12-22 19:02:07.347978	Words (Between The Lines Of Age)	153	2	5	147	97	{}
94	2019-12-22 19:02:07.347978	Born In The U.S.A.	195	1	1	177	98	{}
95	2019-12-22 19:02:07.347978	Cover Me	195	1	2	177	99	{}
96	2019-12-22 19:02:07.347978	Darlington County	195	1	3	177	100	{}
97	2019-12-22 19:02:07.347978	Working On The Highway	195	1	4	177	101	{}
98	2019-12-22 19:02:07.347978	Downbound Train	195	1	5	177	102	{}
99	2019-12-22 19:02:07.347978	I'm On Fire	195	1	6	177	103	{}
100	2019-12-22 19:02:07.347978	No Surrender	195	2	1	177	104	{}
101	2019-12-22 19:02:07.347978	Bobby Jean	195	2	2	177	105	{}
102	2019-12-22 19:02:07.347978	I'm Goin' Down	195	2	3	177	106	{}
103	2019-12-22 19:02:07.347978	Glory Days	195	2	4	177	107	{}
104	2019-12-22 19:02:07.347978	Dancing In The Dark	195	2	5	177	108	{}
105	2019-12-22 19:02:07.347978	My Hometown	195	2	6	177	109	{}
106	2019-12-22 19:02:07.347978	Movin' Out (Anthony's Song)	101	1	1	97	110	{}
107	2019-12-22 19:02:07.347978	The Stranger	101	1	2	97	111	{}
108	2019-12-22 19:02:07.347978	Just The Way You Are	101	1	3	97	112	{}
109	2019-12-22 19:02:07.347978	Scenes From An Italian Restaurant	101	1	4	97	113	{}
110	2019-12-22 19:02:07.347978	Vienna	101	2	1	97	114	{}
111	2019-12-22 19:02:07.347978	Only The Good Die Young	101	2	2	97	115	{}
112	2019-12-22 19:02:07.347978	She's Always A Woman	101	2	3	97	116	{}
113	2019-12-22 19:02:07.347978	Get It Right The First Time	101	2	4	97	117	{}
114	2019-12-22 19:02:07.347978	Everybody Has A Dream	101	2	5	97	118	{}
115	2019-12-22 19:02:07.347978	Untitled	101	2	6	97	119	{}
116	2019-12-22 19:02:07.347978	Good Times Roll	216	1	1	190	120	{}
117	2019-12-22 19:02:07.347978	My Best Friend's Girl	216	1	2	190	121	{}
118	2019-12-22 19:02:07.347978	Just What I Needed	216	1	3	190	122	{}
119	2019-12-22 19:02:07.347978	I'm In Touch With Your World	216	1	4	190	123	{}
120	2019-12-22 19:02:07.347978	Don't Cha Stop	216	1	5	190	124	{}
121	2019-12-22 19:02:07.347978	You're All I've Got Tonight	216	2	1	190	125	{}
122	2019-12-22 19:02:07.347978	Bye Bye Love	216	2	2	190	126	{}
123	2019-12-22 19:02:07.347978	Moving In Stereo	216	2	3	190	127	{}
124	2019-12-22 19:02:07.347978	All Mixed Up	216	2	4	190	128	{}
125	2019-12-22 19:02:07.347978	Carry On	102	1	1	98	129	{}
126	2019-12-22 19:02:07.347978	Teach Your Children	102	1	2	98	130	{}
127	2019-12-22 19:02:07.347978	Almost Cut My Hair	102	1	3	98	131	{}
128	2019-12-22 19:02:07.347978	Helpless	102	1	4	98	132	{}
129	2019-12-22 19:02:07.347978	Woodstock	102	1	5	98	133	{}
130	2019-12-22 19:02:07.347978	Déjà Vu	102	2	1	98	134	{}
131	2019-12-22 19:02:07.347978	Our House	102	2	2	98	135	{}
132	2019-12-22 19:02:07.347978	4 + 20	102	2	3	98	136	{}
133	2019-12-22 19:02:07.347978	Country Girl	102	2	4	98	137	{}
134	2019-12-22 19:02:07.347978	Everybody I Love You	102	2	5	98	138	{}
135	2019-12-22 19:02:07.347978	Hotel California	149	1	1	142	139	{}
136	2019-12-22 19:02:07.347978	New Kid In Town	149	1	2	142	140	{}
137	2019-12-22 19:02:07.347978	Life In The Fast Lane	149	1	3	142	141	{}
138	2019-12-22 19:02:07.347978	Wasted Time	149	1	4	142	142	{}
139	2019-12-22 19:02:07.347978	Wasted Time (Reprise)	149	2	1	142	143	{}
140	2019-12-22 19:02:07.347978	Victim Of Love	149	2	2	142	144	{}
141	2019-12-22 19:02:07.347978	Pretty Maids All In A Row	149	2	3	142	145	{}
142	2019-12-22 19:02:07.347978	Try And Love Again	149	2	4	142	146	{}
143	2019-12-22 19:02:07.347978	The Last Resort	149	2	5	142	147	{}
144	2019-12-22 19:02:07.347978	Fleet Foxes	160	1	2	157	148	{}
145	2019-12-22 19:02:07.347978	Sun It Rises	160	2	1	157	149	{}
146	2019-12-22 19:02:07.347978	White Winter Hymnal	160	2	2	157	150	{}
147	2019-12-22 19:02:07.347978	Ragged Wood	160	2	3	157	151	{}
148	2019-12-22 19:02:07.347978	Tiger Mountain Peasant Song	160	2	4	157	152	{}
149	2019-12-22 19:02:07.347978	Quiet Houses	160	2	5	157	153	{}
150	2019-12-22 19:02:07.347978	He Doesn't Know Why	160	2	6	157	154	{}
151	2019-12-22 19:02:07.347978	Heard Them Stirring	160	3	1	157	155	{}
152	2019-12-22 19:02:07.347978	Your Protector	160	3	2	157	156	{}
153	2019-12-22 19:02:07.347978	Meadowlarks	160	3	3	157	157	{}
154	2019-12-22 19:02:07.347978	Blue Ridge Mountains	160	3	4	157	158	{}
155	2019-12-22 19:02:07.347978	Oliver James	160	3	5	157	159	{}
156	2019-12-22 19:02:07.347978	Sun Giant EP	160	3	6	157	160	{}
157	2019-12-22 19:02:07.347978	Sun Giant	160	4	1	157	161	{}
158	2019-12-22 19:02:07.347978	Drops In The River	160	4	2	157	162	{}
159	2019-12-22 19:02:07.347978	English House	160	4	3	157	163	{}
160	2019-12-22 19:02:07.347978	Mykonos	160	5	1	157	164	{}
161	2019-12-22 19:02:07.347978	Innocent Son	160	5	2	157	165	{}
162	2019-12-22 19:02:07.347978	Two Of Us	184	1	1	171	166	{}
163	2019-12-22 19:02:07.347978	I Dig A Pony	184	1	2	171	167	{}
164	2019-12-22 19:02:07.347978	Across The Universe	184	1	3	171	168	{}
165	2019-12-22 19:02:07.347978	I Me Mine	184	1	4	171	169	{}
166	2019-12-22 19:02:07.347978	Dig It	184	1	5	171	170	{}
167	2019-12-22 19:02:07.347978	Let It Be	184	1	6	171	171	{}
168	2019-12-22 19:02:07.347978	Maggie Mae	184	1	7	171	172	{}
169	2019-12-22 19:02:07.347978	I've Got A Feeling	184	2	1	171	173	{}
170	2019-12-22 19:02:07.347978	One After 909	184	2	2	171	174	{}
171	2019-12-22 19:02:07.347978	The Long And Winding Road	184	2	3	171	175	{}
172	2019-12-22 19:02:07.347978	For You Blue	184	2	4	171	176	{}
173	2019-12-22 19:02:07.347978	Get Back	184	2	5	171	177	{}
174	2019-12-22 19:02:07.347978	Bridge Over Troubled Water	133	1	1	128	178	{}
175	2019-12-22 19:02:07.347978	El Condor Pasa	133	1	2	128	179	{}
176	2019-12-22 19:02:07.347978	Cecilia	133	1	3	128	180	{}
177	2019-12-22 19:02:07.347978	Keep The Customer Satisfied	133	1	4	128	181	{}
178	2019-12-22 19:02:07.347978	So Long, Frank Lloyd Wright	133	1	5	128	182	{}
179	2019-12-22 19:02:07.347978	The Boxer	133	2	1	128	183	{}
180	2019-12-22 19:02:07.347978	Baby Driver	133	2	2	128	184	{}
181	2019-12-22 19:02:07.347978	The Only Living Boy In New York	133	2	3	128	185	{}
182	2019-12-22 19:02:07.347978	Why Don't You Write Me	133	2	4	128	186	{}
183	2019-12-22 19:02:07.347978	Bye Bye Love	133	2	5	128	187	{}
184	2019-12-22 19:02:07.347978	Song For The Asking	133	2	6	128	188	{}
185	2019-12-22 19:02:07.347978	The Chronic (Intro)	221	1	1	196	189	{}
186	2019-12-22 19:02:07.347978	F_ _ _ Wit Dre Day (And Everybody's Celebratin')	221	1	2	196	190	{}
187	2019-12-22 19:02:07.347978	Let Me Ride	221	1	3	196	191	{}
188	2019-12-22 19:02:07.347978	The Day The Niggaz Took Over	221	1	4	196	192	{}
189	2019-12-22 19:02:07.347978	Nuthin' But A "G" Thang	221	2	1	196	193	{}
190	2019-12-22 19:02:07.347978	Deeez Nuuuts	221	2	2	196	194	{}
191	2019-12-22 19:02:07.347978	Lil' Ghetto Boy	221	2	3	196	195	{}
192	2019-12-22 19:02:07.347978	A Nigga Witta Gun	221	3	1	196	196	{}
193	2019-12-22 19:02:07.347978	Rat-Tat-Tat-Tat	221	3	2	196	197	{}
194	2019-12-22 19:02:07.347978	The $20 Sack Pyramid	221	3	3	196	198	{}
195	2019-12-22 19:02:07.347978	Lyrical Gangbang	221	3	4	196	199	{}
196	2019-12-22 19:02:07.347978	High Powered	221	3	5	196	200	{}
197	2019-12-22 19:02:07.347978	The Doctor's Office	221	4	1	196	201	{}
198	2019-12-22 19:02:07.347978	Stranded On Death Row	221	4	2	196	202	{}
199	2019-12-22 19:02:07.347978	The Roach (The Chronic Outro)	221	4	3	196	203	{}
200	2019-12-22 19:02:07.347978	Bitches Ain't S _ _ _	221	4	4	196	204	{}
201	2019-12-22 19:02:07.347978	In The Flesh?	129	1	1	127	205	{}
202	2019-12-22 19:02:07.347978	The Thin Ice	129	1	2	127	206	{}
203	2019-12-22 19:02:07.347978	Another Brick In The Wall Part 1	129	1	3	127	207	{}
204	2019-12-22 19:02:07.347978	The Happiest Days Of Our Lives	129	1	4	127	208	{}
205	2019-12-22 19:02:07.347978	Another Brick In The Wall Part 2	129	1	5	127	209	{}
206	2019-12-22 19:02:07.347978	Mother	129	1	6	127	210	{}
207	2019-12-22 19:02:07.347978	Goodbye Blue Sky	129	2	1	127	211	{}
208	2019-12-22 19:02:07.347978	Empty Spaces	129	2	2	127	212	{}
209	2019-12-22 19:02:07.347978	Young Lust	129	2	3	127	213	{}
210	2019-12-22 19:02:07.347978	One Of My Turns	129	2	4	127	214	{}
211	2019-12-22 19:02:07.347978	Don't Leave Me Now	129	2	5	127	215	{}
212	2019-12-22 19:02:07.347978	Another Brick In The Wall Part 3	129	2	6	127	216	{}
213	2019-12-22 19:02:07.347978	Goodbye Cruel World	129	2	7	127	217	{}
214	2019-12-22 19:02:07.347978	Hey You	129	3	1	127	218	{}
215	2019-12-22 19:02:07.347978	Is There Anybody Out There?	129	3	2	127	219	{}
216	2019-12-22 19:02:07.347978	Nobody Home	129	3	3	127	220	{}
217	2019-12-22 19:02:07.347978	Vera	129	3	4	127	221	{}
218	2019-12-22 19:02:07.347978	Bring The Boys Back Home	129	3	5	127	222	{}
219	2019-12-22 19:02:07.347978	Comfortably Numb	129	3	6	127	223	{}
220	2019-12-22 19:02:07.347978	The Show Must Go On	129	4	1	127	224	{}
221	2019-12-22 19:02:07.347978	In The Flesh	129	4	2	127	225	{}
222	2019-12-22 19:02:07.347978	Run Like Hell	129	4	3	127	226	{}
223	2019-12-22 19:02:07.347978	Waiting For The Worms	129	4	4	127	227	{}
224	2019-12-22 19:02:07.347978	Stop	129	4	5	127	228	{}
225	2019-12-22 19:02:07.347978	The Trial	129	4	6	127	229	{}
226	2019-12-22 19:02:07.347978	Outside The Wall	129	4	7	127	230	{}
227	2019-12-22 19:02:07.347978	Gone Hollywood	108	1	1	107	231	{}
228	2019-12-22 19:02:07.347978	The Logical Song	108	1	2	107	232	{}
229	2019-12-22 19:02:07.347978	Goodbye Stranger	108	1	3	107	233	{}
230	2019-12-22 19:02:07.347978	Breakfast In America	108	1	4	107	234	{}
231	2019-12-22 19:02:07.347978	Oh Darling	108	1	5	107	235	{}
232	2019-12-22 19:02:07.347978	Take The Long Way Home	108	2	1	107	236	{}
233	2019-12-22 19:02:07.347978	Lord Is It Mine	108	2	2	107	237	{}
234	2019-12-22 19:02:07.347978	Just Another Nervous Wreck	108	2	3	107	238	{}
235	2019-12-22 19:02:07.347978	Casual Conversations	108	2	4	107	239	{}
236	2019-12-22 19:02:07.347978	Child Of Vision	108	2	5	107	240	{}
237	2019-12-22 19:02:07.347978	More Than A Feeling	88	1	1	89	241	{}
238	2019-12-22 19:02:07.347978	Peace Of Mind	88	1	2	89	242	{}
239	2019-12-22 19:02:07.347978	Foreplay/Long Time	88	1	3	89	243	{}
240	2019-12-22 19:02:07.347978	Rock & Roll Band	88	2	1	89	244	{}
241	2019-12-22 19:02:07.347978	Smokin'	88	2	2	89	245	{}
242	2019-12-22 19:02:07.347978	Hitch A Ride	88	2	3	89	246	{}
243	2019-12-22 19:02:07.347978	Something About You	88	2	4	89	247	{}
244	2019-12-22 19:02:07.347978	Let Me Take You Home Tonight	88	2	5	89	248	{}
245	2019-12-22 19:02:07.347978	Shine On You Crazy Diamond (1-5)	128	1	2	127	249	{}
246	2019-12-22 19:02:07.347978	Welcome To The Machine	128	2	1	127	250	{}
247	2019-12-22 19:02:07.347978	Have A Cigar	128	3	1	127	251	{}
248	2019-12-22 19:02:07.347978	Wish You Were Here	128	3	2	127	252	{}
249	2019-12-22 19:02:07.347978	Shine On You Crazy Diamond (6-9)	128	3	3	127	253	{}
250	2019-12-22 19:02:07.347978	The Grudge	202	1	1	181	254	{}
251	2019-12-22 19:02:07.347978	Eon Blue Apocalypse	202	1	2	181	255	{}
252	2019-12-22 19:02:07.347978	The Patient	202	1	3	181	256	{}
253	2019-12-22 19:02:07.347978	Mantra	202	1	4	181	257	{}
254	2019-12-22 19:02:07.347978	Schism	202	2	1	181	258	{}
255	2019-12-22 19:02:07.347978	Parabol	202	2	2	181	259	{}
256	2019-12-22 19:02:07.347978	Parabola	202	2	3	181	260	{}
257	2019-12-22 19:02:07.347978	Disposition	202	2	4	181	261	{}
258	2019-12-22 19:02:07.347978	Ticks & Leeches	202	3	1	181	262	{}
259	2019-12-22 19:02:07.347978	Lateralus	202	3	2	181	263	{}
260	2019-12-22 19:02:07.347978	Reflection	202	4	1	181	264	{}
261	2019-12-22 19:02:07.347978	Triad	202	4	2	181	265	{}
262	2019-12-22 19:02:07.347978	Faaip De Oiad	202	4	3	181	266	{}
263	2019-12-22 19:02:07.347978	Lonely Boy	198	1	1	178	267	{}
264	2019-12-22 19:02:07.347978	Dead And Gone	198	1	2	178	268	{}
265	2019-12-22 19:02:07.347978	Gold On The Ceiling	198	1	3	178	269	{}
266	2019-12-22 19:02:07.347978	Little Black Submarines	198	1	4	178	270	{}
267	2019-12-22 19:02:07.347978	Money Maker	198	1	5	178	271	{}
268	2019-12-22 19:02:07.347978	Run Right Back	198	2	1	178	272	{}
269	2019-12-22 19:02:07.347978	Sister	198	2	2	178	273	{}
270	2019-12-22 19:02:07.347978	Hell Of A Season	198	2	3	178	274	{}
271	2019-12-22 19:02:07.347978	Stop Stop	198	2	4	178	275	{}
272	2019-12-22 19:02:07.347978	Nova Baby	198	2	5	178	276	{}
273	2019-12-22 19:02:07.347978	Mind Eraser	198	2	6	178	277	{}
274	2019-12-22 19:02:07.347978	Lonely Boy	198	3	1	178	278	{}
275	2019-12-22 19:02:07.347978	Dead And Gone	198	3	2	178	279	{}
276	2019-12-22 19:02:07.347978	Gold On The Ceiling	198	3	3	178	280	{}
277	2019-12-22 19:02:07.347978	Little Black Submarines	198	3	4	178	281	{}
278	2019-12-22 19:02:07.347978	Money Maker	198	3	5	178	282	{}
279	2019-12-22 19:02:07.347978	Run Right Back	198	3	6	178	283	{}
280	2019-12-22 19:02:07.347978	Sister	198	3	7	178	284	{}
281	2019-12-22 19:02:07.347978	Hell Of A Season	198	3	8	178	285	{}
282	2019-12-22 19:02:07.347978	Stop Stop	198	3	9	178	286	{}
283	2019-12-22 19:02:07.347978	Nova Baby	198	3	10	178	287	{}
284	2019-12-22 19:02:07.347978	Mind Eraser	198	3	11	178	288	{}
285	2019-12-22 19:02:07.347978	Something's Happening	83	1	1	86	289	{}
286	2019-12-22 19:02:07.347978	Doobie Wah	83	1	2	86	290	{}
287	2019-12-22 19:02:07.347978	Show Me The Way	83	1	3	86	291	{}
288	2019-12-22 19:02:07.347978	It's A Plain Shame	83	1	4	86	292	{}
289	2019-12-22 19:02:07.347978	All I Want To Be (Is By Your Side)	83	2	1	86	293	{}
290	2019-12-22 19:02:07.347978	Wind Of Change	83	2	2	86	294	{}
291	2019-12-22 19:02:07.347978	Baby, I Love Your Way	83	2	3	86	295	{}
292	2019-12-22 19:02:07.347978	I Wanna Go To The Sun	83	2	4	86	296	{}
293	2019-12-22 19:02:07.347978	Penny For Your Thoughts	83	3	1	86	297	{}
294	2019-12-22 19:02:07.347978	(I'll Give You) Money	83	3	2	86	298	{}
295	2019-12-22 19:02:07.347978	Shine On	83	3	3	86	299	{}
296	2019-12-22 19:02:07.347978	Jumping Jack Flash	83	3	4	86	300	{}
297	2019-12-22 19:02:07.347978	Lines On My Face	83	4	1	86	301	{}
298	2019-12-22 19:02:07.347978	Do You Feel Like We Do	83	4	2	86	302	{}
299	2019-12-22 19:02:07.347978	Five Years	54	1	1	50	303	{}
300	2019-12-22 19:02:07.347978	Soul Love	54	1	2	50	304	{}
301	2019-12-22 19:02:07.347978	Moonage Daydream	54	1	3	50	305	{}
302	2019-12-22 19:02:07.347978	Starman	54	1	4	50	306	{}
303	2019-12-22 19:02:07.347978	It Ain't Easy	54	1	5	50	307	{}
304	2019-12-22 19:02:07.347978	Lady Stardust	54	2	1	50	308	{}
305	2019-12-22 19:02:07.347978	Star	54	2	2	50	309	{}
306	2019-12-22 19:02:07.347978	Hang On To Yourself	54	2	3	50	310	{}
307	2019-12-22 19:02:07.347978	Ziggy Stardust	54	2	4	50	311	{}
308	2019-12-22 19:02:07.347978	Suffragette City	54	2	5	50	312	{}
309	2019-12-22 19:02:07.347978	Rock 'N' Roll Suicide	54	2	6	50	313	{}
310	2019-12-22 19:02:07.347978	Dark Fantasy	155	1	1	148	314	{}
311	2019-12-22 19:02:07.347978	Gorgeous	155	1	2	148	315	{}
312	2019-12-22 19:02:07.347978	Power	155	2	1	148	316	{}
313	2019-12-22 19:02:07.347978	All Of The Lights (Interlude)	155	2	2	148	317	{}
314	2019-12-22 19:02:07.347978	All Of The Lights	155	2	3	148	318	{}
315	2019-12-22 19:02:07.347978	Monster	155	3	1	148	319	{}
316	2019-12-22 19:02:07.347978	So Appalled	155	4	1	148	320	{}
317	2019-12-22 19:02:07.347978	Devil In A New Dress	155	4	2	148	321	{}
318	2019-12-22 19:02:07.347978	Runaway	155	5	1	148	322	{}
319	2019-12-22 19:02:07.347978	Hell Of A Life	155	5	2	148	323	{}
320	2019-12-22 19:02:07.347978	Blame Game	155	6	1	148	324	{}
321	2019-12-22 19:02:07.347978	Lost In The World	155	6	2	148	325	{}
322	2019-12-22 19:02:07.347978	Who Will Survive In America	155	6	3	148	326	{}
323	2019-12-22 19:02:07.347978	Death With Dignity	45	1	1	42	327	{}
324	2019-12-22 19:02:07.347978	Should Have Known Better	45	1	2	42	328	{}
325	2019-12-22 19:02:07.347978	All Of Me Wants All Of You	45	1	3	42	329	{}
326	2019-12-22 19:02:07.347978	Drawn To The Blood	45	1	4	42	330	{}
327	2019-12-22 19:02:07.347978	Fourth of July	45	1	5	42	331	{}
328	2019-12-22 19:02:07.347978	The Only Thing	45	2	1	42	332	{}
329	2019-12-22 19:02:07.347978	Carrie & Lowell	45	2	2	42	333	{}
330	2019-12-22 19:02:07.347978	Eugene	45	2	3	42	334	{}
331	2019-12-22 19:02:07.347978	John My Beloved	45	2	4	42	335	{}
332	2019-12-22 19:02:07.347978	No Shade In The Shadow Of The Cross	45	2	5	42	336	{}
333	2019-12-22 19:02:07.347978	Blue Bucket Of Gold	45	2	6	42	337	{}
334	2019-12-22 19:02:07.347978	Storm	90	1	2	90	338	{}
335	2019-12-22 19:02:07.347978	Static	90	1	3	90	339	{}
336	2019-12-22 19:02:07.347978	Sleep	90	1	4	90	340	{}
337	2019-12-22 19:02:07.347978	Antennas To Heaven...	90	1	5	90	341	{}
338	2019-12-22 19:02:07.347978	The King Of Carrot Flowers, Pt. One	203	1	1	182	342	{}
339	2019-12-22 19:02:07.347978	The King Of Carrot Flowers, Pts. Two & Three	203	1	2	182	343	{}
340	2019-12-22 19:02:07.347978	In The Aeroplane Over The Sea	203	1	3	182	344	{}
341	2019-12-22 19:02:07.347978	Two-Headed Boy	203	1	4	182	345	{}
342	2019-12-22 19:02:07.347978	The Fool	203	1	5	182	346	{}
343	2019-12-22 19:02:07.347978	Holland, 1945	203	1	6	182	347	{}
344	2019-12-22 19:02:07.347978	Communist Daughter	203	1	7	182	348	{}
345	2019-12-22 19:02:07.347978	Oh Comely	203	2	1	182	349	{}
346	2019-12-22 19:02:07.347978	Ghost	203	2	2	182	350	{}
347	2019-12-22 19:02:07.347978	Untitled	203	2	3	182	351	{}
348	2019-12-22 19:02:07.347978	Two-Headed Boy, Pt. Two	203	2	4	182	352	{}
349	2019-12-22 19:02:07.347978	Wanted Man	175	1	1	166	353	{}
350	2019-12-22 19:02:07.347978	Wreck Of The Old 97	175	1	2	166	354	{}
351	2019-12-22 19:02:07.347978	I Walk The Line	175	1	3	166	355	{}
352	2019-12-22 19:02:07.347978	Darling Companion	175	1	4	166	356	{}
353	2019-12-22 19:02:07.347978	Starkville City Jail	175	1	5	166	357	{}
354	2019-12-22 19:02:07.347978	San Quentin	175	2	1	166	358	{}
355	2019-12-22 19:02:07.347978	San Quentin	175	2	2	166	359	{}
356	2019-12-22 19:02:07.347978	A Boy Named Sue	175	2	3	166	360	{}
357	2019-12-22 19:02:07.347978	(There'll Be) Peace In The Valley	175	2	4	166	361	{}
358	2019-12-22 19:02:07.347978	Folsom Prison Blues	175	2	5	166	362	{}
359	2019-12-22 19:02:07.347978	You May Be Right	100	1	1	97	363	{}
360	2019-12-22 19:02:07.347978	Sometimes A Fantasy	100	1	2	97	364	{}
361	2019-12-22 19:02:07.347978	Don't Ask Me Why	100	1	3	97	365	{}
362	2019-12-22 19:02:07.347978	It's Still Rock And Roll To Me	100	1	4	97	366	{}
363	2019-12-22 19:02:07.347978	All For Leyna	100	1	5	97	367	{}
364	2019-12-22 19:02:07.347978	I Don't Want To Be Alone	100	2	1	97	368	{}
365	2019-12-22 19:02:07.347978	Sleeping With The Television On	100	2	2	97	369	{}
366	2019-12-22 19:02:07.347978	C'Etait Toi (You Were The One)	100	2	3	97	370	{}
367	2019-12-22 19:02:07.347978	Close To The Borderline	100	2	4	97	371	{}
368	2019-12-22 19:02:07.347978	Through The Long Night	100	2	5	97	372	{}
369	2019-12-22 19:02:07.347978	Toys In The Attic	85	1	1	87	373	{}
370	2019-12-22 19:02:07.347978	Uncle Salty	85	1	2	87	374	{}
371	2019-12-22 19:02:07.347978	Adam's Apple	85	1	3	87	375	{}
372	2019-12-22 19:02:07.347978	Walk This Way	85	1	4	87	376	{}
373	2019-12-22 19:02:07.347978	Big Ten Inch Record	85	1	5	87	377	{}
374	2019-12-22 19:02:07.347978	Sweet Emotion	85	2	1	87	378	{}
375	2019-12-22 19:02:07.347978	No More No More	85	2	2	87	379	{}
376	2019-12-22 19:02:07.347978	Round And Round	85	2	3	87	380	{}
377	2019-12-22 19:02:07.347978	You See Me Crying	85	2	4	87	381	{}
378	2019-12-22 19:02:07.347978	I Feel The Earth Move	138	1	1	135	382	{}
379	2019-12-22 19:02:07.347978	So Far Away	138	1	2	135	383	{}
380	2019-12-22 19:02:07.347978	It's Too Late	138	1	3	135	384	{}
381	2019-12-22 19:02:07.347978	Home Again	138	1	4	135	385	{}
382	2019-12-22 19:02:07.347978	Beautiful	138	1	5	135	386	{}
383	2019-12-22 19:02:07.347978	Way Over Yonder	138	1	6	135	387	{}
384	2019-12-22 19:02:07.347978	You've Got A Friend	138	2	1	135	388	{}
385	2019-12-22 19:02:07.347978	Where You Lead	138	2	2	135	389	{}
386	2019-12-22 19:02:07.347978	Will You Love Me Tomorrow?	138	2	3	135	390	{}
387	2019-12-22 19:02:07.347978	Smackwater Jack	138	2	4	135	391	{}
388	2019-12-22 19:02:07.347978	Tapestry	138	2	5	135	392	{}
389	2019-12-22 19:02:07.347978	(You Make Me Feel Like) A Natural Woman	138	2	6	135	393	{}
390	2019-12-22 19:02:07.347978	Flume	104	1	1	99	394	{}
391	2019-12-22 19:02:07.347978	Lump Sum	104	1	2	99	395	{}
392	2019-12-22 19:02:07.347978	Skinny Love	104	1	3	99	396	{}
393	2019-12-22 19:02:07.347978	The Wolves (Act I And II)	104	1	4	99	397	{}
394	2019-12-22 19:02:07.347978	Blindsided	104	2	1	99	398	{}
395	2019-12-22 19:02:07.347978	Creature Fear	104	2	2	99	399	{}
396	2019-12-22 19:02:07.347978	Team	104	2	3	99	400	{}
397	2019-12-22 19:02:07.347978	For Emma	104	2	4	99	401	{}
398	2019-12-22 19:02:07.347978	Re: Stacks	104	2	5	99	402	{}
399	2019-12-22 19:02:07.347978	★ (Blackstar)	53	1	1	50	403	{}
400	2019-12-22 19:02:07.347978	'Tis A Pity She Was A Whore	53	1	2	50	404	{}
401	2019-12-22 19:02:07.347978	Lazarus	53	1	3	50	405	{}
402	2019-12-22 19:02:07.347978	Sue (Or In A Season Of Crime)	53	2	1	50	406	{}
403	2019-12-22 19:02:07.347978	Girl Loves Me	53	2	2	50	407	{}
404	2019-12-22 19:02:07.347978	Dollar Days	53	2	3	50	408	{}
405	2019-12-22 19:02:07.347978	I Can't Give Everything Away	53	2	4	50	409	{}
406	2019-12-22 19:02:07.347978	Start Me Up	163	1	1	158	410	{}
407	2019-12-22 19:02:07.347978	Hang Fire	163	1	2	158	411	{}
408	2019-12-22 19:02:07.347978	Slave	163	1	3	158	412	{}
409	2019-12-22 19:02:07.347978	Little T & A	163	1	4	158	413	{}
410	2019-12-22 19:02:07.347978	Black Limousine	163	1	5	158	414	{}
411	2019-12-22 19:02:07.347978	Neighbours	163	1	6	158	415	{}
412	2019-12-22 19:02:07.347978	Worried About You	163	2	1	158	416	{}
413	2019-12-22 19:02:07.347978	Tops	163	2	2	158	417	{}
414	2019-12-22 19:02:07.347978	Heaven	163	2	3	158	418	{}
415	2019-12-22 19:02:07.347978	No Use In Crying	163	2	4	158	419	{}
416	2019-12-22 19:02:07.347978	Waiting On A Friend	163	2	5	158	420	{}
417	2019-12-22 19:02:07.347978	The Illest Villains	204	1	1	183	421	{}
418	2019-12-22 19:02:07.347978	Accordion	204	2	1	183	422	{}
419	2019-12-22 19:02:07.347978	Meat Grinder	204	3	1	183	423	{}
420	2019-12-22 19:02:07.347978	Bistro	204	4	1	183	424	{}
421	2019-12-22 19:02:07.347978	Raid	204	5	1	183	425	{}
422	2019-12-22 19:02:07.347978	America's Most Blunted	204	6	1	183	426	{}
423	2019-12-22 19:02:07.347978	Sickfit (Inst.)	204	7	1	183	427	{}
424	2019-12-22 19:02:07.347978	Rainbows	204	8	1	183	428	{}
425	2019-12-22 19:02:07.347978	Curls	204	9	1	183	429	{}
426	2019-12-22 19:02:07.347978	Do Not Fire! (Inst.)	204	10	1	183	430	{}
427	2019-12-22 19:02:07.347978	Money Folder	204	11	1	183	431	{}
428	2019-12-22 19:02:07.347978	Scene Two (Voice Skit)	204	12	1	183	432	{}
429	2019-12-22 19:02:07.347978	Shadows Of Tomorrow	204	13	1	183	433	{}
430	2019-12-22 19:02:07.347978	Operation Lifesaver AKA Mint Test	204	14	1	183	434	{}
431	2019-12-22 19:02:07.347978	Figaro	204	15	1	183	435	{}
432	2019-12-22 19:02:07.347978	Hardcore Hustle	204	16	1	183	436	{}
433	2019-12-22 19:02:07.347978	Strange Ways	204	17	1	183	437	{}
434	2019-12-22 19:02:07.347978	(Intro)	204	18	1	183	438	{}
435	2019-12-22 19:02:07.347978	Fancy Clown	204	19	1	183	439	{}
436	2019-12-22 19:02:07.347978	Eye	204	20	1	183	440	{}
437	2019-12-22 19:02:07.347978	Supervillain Theme (Inst.)	204	21	1	183	441	{}
438	2019-12-22 19:02:07.347978	All Caps	204	22	1	183	442	{}
439	2019-12-22 19:02:07.347978	Great Day	204	23	1	183	443	{}
440	2019-12-22 19:02:07.347978	Rhinestone Cowboy	204	24	1	183	444	{}
441	2019-12-22 19:02:07.347978	Don't Stop Believin'	46	1	1	43	445	{}
442	2019-12-22 19:02:07.347978	Stone In Love	46	1	2	43	446	{}
443	2019-12-22 19:02:07.347978	Who's Crying Now	46	1	3	43	447	{}
444	2019-12-22 19:02:07.347978	Keep On Runnin'	46	1	4	43	448	{}
445	2019-12-22 19:02:07.347978	Still They Ride	46	1	5	43	449	{}
446	2019-12-22 19:02:07.347978	Escape	46	2	1	43	450	{}
447	2019-12-22 19:02:07.347978	Lay It Down	46	2	2	43	451	{}
448	2019-12-22 19:02:07.347978	Dead Or Alive	46	2	3	43	452	{}
449	2019-12-22 19:02:07.347978	Mother, Father	46	2	4	43	453	{}
450	2019-12-22 19:02:07.347978	Open Arms	46	2	5	43	454	{}
451	2019-12-22 19:02:07.347978	Smells Like Teen Spirit	110	1	1	108	455	{}
452	2019-12-22 19:02:07.347978	In Bloom	110	1	2	108	456	{}
453	2019-12-22 19:02:07.347978	Come As You Are	110	1	3	108	457	{}
454	2019-12-22 19:02:07.347978	Breed	110	1	4	108	458	{}
455	2019-12-22 19:02:07.347978	Lithium	110	1	5	108	459	{}
456	2019-12-22 19:02:07.347978	Polly	110	1	6	108	460	{}
457	2019-12-22 19:02:07.347978	Territorial Pissings	110	2	1	108	461	{}
458	2019-12-22 19:02:07.347978	Drain You	110	2	2	108	462	{}
459	2019-12-22 19:02:07.347978	Lounge Act	110	2	3	108	463	{}
460	2019-12-22 19:02:07.347978	Stay Away	110	2	4	108	464	{}
461	2019-12-22 19:02:07.347978	On A Plain	110	2	5	108	465	{}
462	2019-12-22 19:02:07.347978	Something In The Way	110	2	6	108	466	{}
463	2019-12-22 19:02:07.347978	Bad	6	1	1	7	467	{}
464	2019-12-22 19:02:07.347978	The Way You Make Me Feel	6	1	2	7	468	{}
465	2019-12-22 19:02:07.347978	Speed Demon	6	1	3	7	469	{}
466	2019-12-22 19:02:07.347978	Liberian Girl	6	1	4	7	470	{}
467	2019-12-22 19:02:07.347978	Just Good Friends	6	1	5	7	471	{}
468	2019-12-22 19:02:07.347978	Another Part Of Me	6	2	1	7	472	{}
469	2019-12-22 19:02:07.347978	Man In The Mirror	6	2	2	7	473	{}
470	2019-12-22 19:02:07.347978	I Just Can't Stop Loving You	6	2	3	7	474	{}
471	2019-12-22 19:02:07.347978	Dirty Diana	6	2	4	7	475	{}
472	2019-12-22 19:02:07.347978	Smooth Criminal	6	2	5	7	476	{}
473	2019-12-22 19:02:07.347978	Under The Pressure	86	1	1	88	477	{}
474	2019-12-22 19:02:07.347978	Red Eyes	86	1	2	88	478	{}
475	2019-12-22 19:02:07.347978	Suffering	86	1	3	88	479	{}
476	2019-12-22 19:02:07.347978	An Ocean In Between The Waves	86	2	1	88	480	{}
477	2019-12-22 19:02:07.347978	Disappearing	86	2	2	88	481	{}
478	2019-12-22 19:02:07.347978	Eyes To The Wind	86	3	1	88	482	{}
479	2019-12-22 19:02:07.347978	The Haunting Idle	86	3	2	88	483	{}
480	2019-12-22 19:02:07.347978	Burning	86	3	3	88	484	{}
481	2019-12-22 19:02:07.347978	Lost In The Dream	86	4	1	88	485	{}
482	2019-12-22 19:02:07.347978	In Reverse	86	4	2	88	486	{}
483	2019-12-22 19:02:07.347978	Shaolin Sword	117	1	2	115	487	{}
484	2019-12-22 19:02:07.347978	Bring Da Ruckus	117	2	1	115	488	{}
485	2019-12-22 19:02:07.347978	Shame On A Nigga	117	2	2	115	489	{}
486	2019-12-22 19:02:07.347978	Clan In Da Front	117	2	3	115	490	{}
487	2019-12-22 19:02:07.347978	Wu-Tang: 7th Chamber	117	2	4	115	491	{}
488	2019-12-22 19:02:07.347978	Can It Be All So Simple	117	2	5	115	492	{}
489	2019-12-22 19:02:07.347978	Protect Ya Neck (Intermission)	117	2	6	115	493	{}
490	2019-12-22 19:02:07.347978	Wu-Tang Sword	117	2	7	115	494	{}
491	2019-12-22 19:02:07.347978	Da Mystery Of Chessboxin'	117	3	1	115	495	{}
492	2019-12-22 19:02:07.347978	Wu-Tang Clan Ain't Nuthing Ta F' Wit	117	3	2	115	496	{}
493	2019-12-22 19:02:07.347978	C.R.E.A.M.	117	3	3	115	497	{}
494	2019-12-22 19:02:07.347978	Method Man	117	3	4	115	498	{}
495	2019-12-22 19:02:07.347978	Tearz	117	3	5	115	499	{}
496	2019-12-22 19:02:07.347978	Wu-Tang: 7th Chamber - Part II	117	3	6	115	500	{}
497	2019-12-22 19:02:07.347978	Conclusion	117	3	7	115	501	{}
498	2019-12-22 19:02:07.347978	15 Step	24	1	1	17	502	{}
499	2019-12-22 19:02:07.347978	Bodysnatchers	24	1	2	17	503	{}
500	2019-12-22 19:02:07.347978	Nude	24	1	3	17	504	{}
501	2019-12-22 19:02:07.347978	Weird Fishes/Arpeggi	24	1	4	17	505	{}
502	2019-12-22 19:02:07.347978	All I Need	24	1	5	17	506	{}
503	2019-12-22 19:02:07.347978	Faust Arp	24	2	1	17	507	{}
504	2019-12-22 19:02:07.347978	Reckoner	24	2	2	17	508	{}
505	2019-12-22 19:02:07.347978	House Of Cards	24	2	3	17	509	{}
506	2019-12-22 19:02:07.347978	Jigsaw Falling Into Place	24	2	4	17	510	{}
507	2019-12-22 19:02:07.347978	Videotape	24	2	5	17	511	{}
508	2019-12-22 19:02:07.347978	Don't Stop 'Til You Get Enough	5	1	1	7	512	{}
509	2019-12-22 19:02:07.347978	Rock With You	5	1	2	7	513	{}
510	2019-12-22 19:02:07.347978	Working Day And Night	5	1	3	7	514	{}
511	2019-12-22 19:02:07.347978	Get On The Floor	5	1	4	7	515	{}
512	2019-12-22 19:02:07.347978	Off The Wall	5	2	1	7	516	{}
513	2019-12-22 19:02:07.347978	Girlfriend	5	2	2	7	517	{}
514	2019-12-22 19:02:07.347978	She's Out Of My Life	5	2	3	7	518	{}
515	2019-12-22 19:02:07.347978	I Can't Help It	5	2	4	7	519	{}
516	2019-12-22 19:02:07.347978	It's The Falling In Love	5	2	5	7	520	{}
517	2019-12-22 19:02:07.347978	Burn This Disco Out	5	2	6	7	521	{}
518	2019-12-22 19:02:07.347978	Do I Wanna Know?	177	1	1	167	522	{}
519	2019-12-22 19:02:07.347978	R U Mine?	177	1	2	167	523	{}
520	2019-12-22 19:02:07.347978	One For The Road	177	1	3	167	524	{}
521	2019-12-22 19:02:07.347978	Arabella	177	1	4	167	525	{}
522	2019-12-22 19:02:07.347978	I Want It All	177	1	5	167	526	{}
523	2019-12-22 19:02:07.347978	No.1 Party Anthem	177	1	6	167	527	{}
524	2019-12-22 19:02:07.347978	Mad Sounds	177	2	1	167	528	{}
525	2019-12-22 19:02:07.347978	Fireside	177	2	2	167	529	{}
526	2019-12-22 19:02:07.347978	Why'd You Only Call Me When You're High?	177	2	3	167	530	{}
527	2019-12-22 19:02:07.347978	Snap Out Of It 	177	2	4	167	531	{}
528	2019-12-22 19:02:07.347978	Knee Socks	177	2	5	167	532	{}
529	2019-12-22 19:02:07.347978	I Wanna Be Yours	177	2	6	167	533	{}
530	2019-12-22 19:02:07.347978	The Heart Of Rock & Roll	31	1	1	30	534	{}
531	2019-12-22 19:02:07.347978	Heart And Soul	31	1	2	30	535	{}
532	2019-12-22 19:02:07.347978	Bad Is Bad	31	1	3	30	536	{}
533	2019-12-22 19:02:07.347978	I Want A New Drug	31	1	4	30	537	{}
534	2019-12-22 19:02:07.347978	Walking On A Thin Line	31	2	1	30	538	{}
535	2019-12-22 19:02:07.347978	Finally Found A Home	31	2	2	30	539	{}
536	2019-12-22 19:02:07.347978	If This Is It	31	2	3	30	540	{}
537	2019-12-22 19:02:07.347978	You Crack Me Up	31	2	4	30	541	{}
538	2019-12-22 19:02:07.347978	Honky Tonk Blues	31	2	5	30	542	{}
539	2019-12-22 19:02:07.347978	Come Together	183	1	1	171	543	{}
540	2019-12-22 19:02:07.347978	Something	183	1	2	171	544	{}
541	2019-12-22 19:02:07.347978	Maxwell's Silver Hammer	183	1	3	171	545	{}
542	2019-12-22 19:02:07.347978	Oh! Darling	183	1	4	171	546	{}
543	2019-12-22 19:02:07.347978	Octopus's Garden	183	1	5	171	547	{}
544	2019-12-22 19:02:07.347978	I Want You (She's So Heavy)	183	1	6	171	548	{}
545	2019-12-22 19:02:07.347978	Here Comes The Sun	183	2	1	171	549	{}
546	2019-12-22 19:02:07.347978	Because	183	2	2	171	550	{}
547	2019-12-22 19:02:07.347978	You Never Give Me Your Money	183	2	3	171	551	{}
548	2019-12-22 19:02:07.347978	Sun King	183	2	4	171	552	{}
549	2019-12-22 19:02:07.347978	Mean Mr. Mustard	183	2	5	171	553	{}
550	2019-12-22 19:02:07.347978	Polythene Pam	183	2	6	171	554	{}
551	2019-12-22 19:02:07.347978	She Came In Through The Bathroom Window	183	2	7	171	555	{}
552	2019-12-22 19:02:07.347978	Golden Slumbers	183	2	8	171	556	{}
553	2019-12-22 19:02:07.347978	Carry That Weight	183	2	9	171	557	{}
554	2019-12-22 19:02:07.347978	The End	183	2	10	171	558	{}
555	2019-12-22 19:02:07.347978	Her Majesty	183	2	11	171	559	{}
556	2019-12-22 19:02:07.347978	Hello	218	1	1	191	560	{}
557	2019-12-22 19:02:07.347978	Roll With It	218	1	2	191	561	{}
558	2019-12-22 19:02:07.347978	Wonderwall	218	1	3	191	562	{}
559	2019-12-22 19:02:07.347978	Don't Look Back In Anger	218	2	1	191	563	{}
560	2019-12-22 19:02:07.347978	Hey Now!	218	2	2	191	564	{}
561	2019-12-22 19:02:07.347978	Untitled	218	2	3	191	565	{}
562	2019-12-22 19:02:07.347978	Bonehead's Bank Holiday	218	2	4	191	566	{}
563	2019-12-22 19:02:07.347978	Some Might Say	218	3	1	191	567	{}
564	2019-12-22 19:02:07.347978	Cast No Shadow	218	3	2	191	568	{}
565	2019-12-22 19:02:07.347978	She's Electric	218	3	3	191	569	{}
566	2019-12-22 19:02:07.347978	Morning Glory	218	4	1	191	570	{}
567	2019-12-22 19:02:07.347978	Untitled	218	4	2	191	571	{}
568	2019-12-22 19:02:07.347978	Champagne Supernova	218	4	3	191	572	{}
569	2019-12-22 19:02:07.347978	Folsom Prison Blues	174	1	1	166	573	{}
570	2019-12-22 19:02:07.347978	Dark As The Dungeon	174	1	2	166	574	{}
571	2019-12-22 19:02:07.347978	I Still Miss Someone	174	1	3	166	575	{}
572	2019-12-22 19:02:07.347978	Cocaine Blues	174	1	4	166	576	{}
573	2019-12-22 19:02:07.347978	25 Minutes To Go	174	1	5	166	577	{}
574	2019-12-22 19:02:07.347978	Orange Blossom Special	174	1	6	166	578	{}
575	2019-12-22 19:02:07.347978	The Long Black Veil	174	1	7	166	579	{}
576	2019-12-22 19:02:07.347978	Send A Picture Of Mother	174	2	1	166	580	{}
577	2019-12-22 19:02:07.347978	The Wall	174	2	2	166	581	{}
578	2019-12-22 19:02:07.347978	Dirty Old Egg-Sucking Dog	174	2	3	166	582	{}
579	2019-12-22 19:02:07.347978	Flushed From The Bathroom Of Your Heart	174	2	4	166	583	{}
580	2019-12-22 19:02:07.347978	Jackson	174	2	5	166	584	{}
581	2019-12-22 19:02:07.347978	Give My Love To Rose	174	2	6	166	585	{}
582	2019-12-22 19:02:07.347978	I Got Stripes	174	2	7	166	586	{}
583	2019-12-22 19:02:07.347978	Green, Green Grass Of Home	174	2	8	166	587	{}
584	2019-12-22 19:02:07.347978	Greystone Chapel	174	2	9	166	588	{}
585	2019-12-22 19:02:07.347978	Eeny	23	1	2	17	589	{}
586	2019-12-22 19:02:07.347978	Airbag	23	2	1	17	590	{}
587	2019-12-22 19:02:07.347978	Paranoid Android	23	2	2	17	591	{}
588	2019-12-22 19:02:07.347978	Subterranean Homesick Alien	23	2	3	17	592	{}
589	2019-12-22 19:02:07.347978	Meeny	23	2	4	17	593	{}
590	2019-12-22 19:02:07.347978	Exit Music (For A Film)	23	3	1	17	594	{}
591	2019-12-22 19:02:07.347978	Let Down	23	3	2	17	595	{}
592	2019-12-22 19:02:07.347978	Karma Police	23	3	3	17	596	{}
593	2019-12-22 19:02:07.347978	Miney	23	3	4	17	597	{}
594	2019-12-22 19:02:07.347978	Fitter Happier	23	4	1	17	598	{}
595	2019-12-22 19:02:07.347978	Electioneering	23	4	2	17	599	{}
596	2019-12-22 19:02:07.347978	Climbing Up The Walls	23	4	3	17	600	{}
597	2019-12-22 19:02:07.347978	No Surprises	23	4	4	17	601	{}
598	2019-12-22 19:02:07.347978	Mo	23	4	5	17	602	{}
599	2019-12-22 19:02:07.347978	Lucky	23	5	1	17	603	{}
600	2019-12-22 19:02:07.347978	The Tourist	23	5	2	17	604	{}
601	2019-12-22 19:02:07.347978	Main Title	55	1	1	51	605	{}
602	2019-12-22 19:02:07.347978	Imperial Attack	55	1	2	51	606	{}
603	2019-12-22 19:02:07.347978	Princess Leia's Theme	55	1	3	51	607	{}
604	2019-12-22 19:02:07.347978	The Desert And The Robot Auction	55	1	4	51	608	{}
605	2019-12-22 19:02:07.347978	Ben's Death And TIE Fighter Attack	55	2	1	51	609	{}
606	2019-12-22 19:02:07.347978	The Little People Work	55	2	2	51	610	{}
607	2019-12-22 19:02:07.347978	Rescue Of The Princess	55	2	3	51	611	{}
608	2019-12-22 19:02:07.347978	Inner City	55	2	4	51	612	{}
609	2019-12-22 19:02:07.347978	Cantina Band	55	2	5	51	613	{}
610	2019-12-22 19:02:07.347978	The Land Of The Sand People	55	3	1	51	614	{}
611	2019-12-22 19:02:07.347978	Mouse Robot And Blasting Off	55	3	2	51	615	{}
612	2019-12-22 19:02:07.347978	The Return Home	55	3	3	51	616	{}
613	2019-12-22 19:02:07.347978	The Walls Converge	55	3	4	51	617	{}
614	2019-12-22 19:02:07.347978	The Princess Appears	55	3	5	51	618	{}
615	2019-12-22 19:02:07.347978	The Last Battle	55	4	1	51	619	{}
616	2019-12-22 19:02:07.347978	The Throne Room And End Title	55	4	2	51	620	{}
617	2019-12-22 19:02:07.347978	Grease	62	1	1	61	621	{}
618	2019-12-22 19:02:07.347978	Summer Nights	62	1	2	152	622	{}
619	2019-12-22 19:02:07.347978	Hopelessly Devoted To You	62	1	3	74	623	{}
620	2019-12-22 19:02:07.347978	You're The One That I Want	62	1	4	152	624	{}
621	2019-12-22 19:02:07.347978	Sandy	62	1	5	55	625	{}
622	2019-12-22 19:02:07.347978	Beauty School Drop-Out	62	2	1	103	626	{}
623	2019-12-22 19:02:07.347978	Look At Me, I'm Sandra Dee	62	2	2	146	627	{}
624	2019-12-22 19:02:07.347978	Greased Lightnin'	62	2	3	55	628	{}
625	2019-12-22 19:02:07.347978	It's Raining On Prom Night	62	2	4	104	629	{}
626	2019-12-22 19:02:07.347978	Alone At A Drive-In Movie (Instrumental)	62	2	5	75	630	{}
627	2019-12-22 19:02:07.347978	Blue Moon	62	2	6	76	631	{}
628	2019-12-22 19:02:07.347978	Rock 'N' Roll Is Here To Stay	62	3	1	76	632	{}
629	2019-12-22 19:02:07.347978	Those Magic Changes	62	3	2	76	633	{}
630	2019-12-22 19:02:07.347978	Hound Dog	62	3	3	76	634	{}
631	2019-12-22 19:02:07.347978	Born To Hand-Jive	62	3	4	76	635	{}
632	2019-12-22 19:02:07.347978	Tears On My Pillow	62	3	5	76	636	{}
633	2019-12-22 19:02:07.347978	Mooning	62	3	6	73	637	{}
634	2019-12-22 19:02:07.347978	Freddy, My Love	62	4	1	104	638	{}
635	2019-12-22 19:02:07.347978	Rock 'N' Roll Party Queen	62	4	2	20	639	{}
636	2019-12-22 19:02:07.347978	There Are Worse Things I Could Do	62	4	3	146	640	{}
637	2019-12-22 19:02:07.347978	Look At Me, I'm Sandra Dee (Reprise)	62	4	4	74	641	{}
638	2019-12-22 19:02:07.347978	We Go Together	62	4	5	152	642	{}
639	2019-12-22 19:02:07.347978	Love Is A Many Splendored Thing (Instrumental)	62	4	6	75	643	{}
640	2019-12-22 19:02:07.347978	Grease (Reprise)	62	4	7	61	644	{}
641	2019-12-22 19:02:07.347978	Who Can It Be Now?	165	1	1	160	645	{}
642	2019-12-22 19:02:07.347978	I Can See It In Your Eyes	165	1	2	160	646	{}
643	2019-12-22 19:02:07.347978	Down Under	165	1	3	160	647	{}
644	2019-12-22 19:02:07.347978	Underground	165	1	4	160	648	{}
645	2019-12-22 19:02:07.347978	Helpless Automaton	165	1	5	160	649	{}
646	2019-12-22 19:02:07.347978	People Just Love To Play With Words	165	2	1	160	650	{}
647	2019-12-22 19:02:07.347978	Be Good Johnny	165	2	2	160	651	{}
648	2019-12-22 19:02:07.347978	Touching The Untouchables	165	2	3	160	652	{}
649	2019-12-22 19:02:07.347978	Catch A Star	165	2	4	160	653	{}
650	2019-12-22 19:02:07.347978	Down By The Sea	165	2	5	160	654	{}
651	2019-12-22 19:02:07.347978	So Far Away	224	1	1	197	655	{}
652	2019-12-22 19:02:07.347978	Money For Nothing	224	1	2	197	656	{}
653	2019-12-22 19:02:07.347978	Walk Of Life	224	1	3	197	657	{}
654	2019-12-22 19:02:07.347978	Your Latest Trick	224	1	4	197	658	{}
655	2019-12-22 19:02:07.347978	Why Worry	224	1	5	197	659	{}
656	2019-12-22 19:02:07.347978	Ride Across The River	224	2	1	197	660	{}
657	2019-12-22 19:02:07.347978	The Man's Too Strong	224	2	2	197	661	{}
658	2019-12-22 19:02:07.347978	One World	224	2	3	197	662	{}
659	2019-12-22 19:02:07.347978	Brothers In Arms	224	2	4	197	663	{}
660	2019-12-22 19:02:07.347978	So What	134	1	1	129	664	{}
661	2019-12-22 19:02:07.347978	Freddie Freeloader	134	1	2	129	665	{}
662	2019-12-22 19:02:07.347978	Blue In Green	134	1	3	129	666	{}
663	2019-12-22 19:02:07.347978	All Blues	134	2	1	129	667	{}
664	2019-12-22 19:02:07.347978	Flamenco Sketches	134	2	2	129	668	{}
665	2019-12-22 19:02:07.347978	Night Life	47	1	1	44	669	{}
666	2019-12-22 19:02:07.347978	Juke Box Hero	47	1	2	44	670	{}
667	2019-12-22 19:02:07.347978	Break It Up	47	1	3	44	671	{}
668	2019-12-22 19:02:07.347978	Waiting For A Girl Like You	47	1	4	44	672	{}
669	2019-12-22 19:02:07.347978	Luanne	47	1	5	44	673	{}
670	2019-12-22 19:02:07.347978	Urgent	47	2	1	44	674	{}
671	2019-12-22 19:02:07.347978	I'm Gonna Win	47	2	2	44	675	{}
672	2019-12-22 19:02:07.347978	Woman In Black	47	2	3	44	676	{}
673	2019-12-22 19:02:07.347978	Girl On The Moon	47	2	4	44	677	{}
674	2019-12-22 19:02:07.347978	Don't Let Go	47	2	5	44	678	{}
675	2019-12-22 19:02:07.347978	Gemini	200	1	1	179	679	{}
676	2019-12-22 19:02:07.347978	Reach For The Dead	200	1	2	179	680	{}
677	2019-12-22 19:02:07.347978	White Cyclosa	200	1	3	179	681	{}
678	2019-12-22 19:02:07.347978	Jacquard Causeway	200	1	4	179	682	{}
679	2019-12-22 19:02:07.347978	Telepath	200	2	1	179	683	{}
680	2019-12-22 19:02:07.347978	Cold Earth	200	2	2	179	684	{}
681	2019-12-22 19:02:07.347978	Transmisiones Ferox	200	2	3	179	685	{}
682	2019-12-22 19:02:07.347978	Sick Times	200	2	4	179	686	{}
683	2019-12-22 19:02:07.347978	Collapse	200	2	5	179	687	{}
684	2019-12-22 19:02:07.347978	Palace Posy	200	3	1	179	688	{}
685	2019-12-22 19:02:07.347978	Split Your Infinities	200	3	2	179	689	{}
686	2019-12-22 19:02:07.347978	Uritual	200	3	3	179	690	{}
687	2019-12-22 19:02:07.347978	Nothing Is Real	200	3	4	179	691	{}
688	2019-12-22 19:02:07.347978	Sundown	200	3	5	179	692	{}
689	2019-12-22 19:02:07.347978	New Seeds	200	4	1	179	693	{}
690	2019-12-22 19:02:07.347978	Come To Dust	200	4	2	179	694	{}
691	2019-12-22 19:02:07.347978	Semena Mertvykh	200	4	3	179	695	{}
692	2019-12-22 19:02:07.347978	Neighborhood #1 (Tunnels)	188	1	1	173	696	{}
693	2019-12-22 19:02:07.347978	Neighborhood #2 (Laïka)	188	1	2	173	697	{}
694	2019-12-22 19:02:07.347978	Une Année Sans Lumiere	188	1	3	173	698	{}
695	2019-12-22 19:02:07.347978	Neighborhood #3 (Power Out)	188	1	4	173	699	{}
696	2019-12-22 19:02:07.347978	Neighborhood #4 (7 Kettles)	188	1	5	173	700	{}
697	2019-12-22 19:02:07.347978	Crown Of Love	188	2	1	173	701	{}
698	2019-12-22 19:02:07.347978	Wake Up	188	2	2	173	702	{}
699	2019-12-22 19:02:07.347978	Haiti	188	2	3	173	703	{}
700	2019-12-22 19:02:07.347978	Rebellion (Lies)	188	2	4	173	704	{}
701	2019-12-22 19:02:07.347978	In The Backseat	188	2	5	173	705	{}
702	2019-12-22 19:02:07.347978	Strawberry Fields Forever	182	1	1	171	706	{}
703	2019-12-22 19:02:07.347978	Penny Lane	182	1	2	171	707	{}
704	2019-12-22 19:02:07.347978	Sgt. Pepper's Lonely Hearts Club Band	182	1	3	171	708	{}
705	2019-12-22 19:02:07.347978	With A Little Help From My Friends	182	1	4	171	709	{}
706	2019-12-22 19:02:07.347978	Lucy In The Sky With Diamonds	182	1	5	171	710	{}
707	2019-12-22 19:02:07.347978	A Day In The Life	182	1	6	171	711	{}
708	2019-12-22 19:02:07.347978	All You Need Is Love	182	1	7	171	712	{}
709	2019-12-22 19:02:07.347978	I Am The Walrus	182	2	1	171	713	{}
710	2019-12-22 19:02:07.347978	Hello Goodbye	182	2	2	171	714	{}
711	2019-12-22 19:02:07.347978	The Fool On The Hill	182	2	3	171	715	{}
712	2019-12-22 19:02:07.347978	Magical Mystery Tour	182	2	4	171	716	{}
713	2019-12-22 19:02:07.347978	Lady Madonna	182	2	5	171	717	{}
714	2019-12-22 19:02:07.347978	Hey Jude	182	2	6	171	718	{}
715	2019-12-22 19:02:07.347978	Revolution	182	2	7	171	719	{}
716	2019-12-22 19:02:07.347978	Back In The U.S.S.R.	182	3	1	171	720	{}
717	2019-12-22 19:02:07.347978	While My Guitar Gently Weeps	182	3	2	171	721	{}
718	2019-12-22 19:02:07.347978	Ob-La-Di, Ob-La-Da	182	3	3	171	722	{}
719	2019-12-22 19:02:07.347978	Get Back	182	3	4	171	723	{}
720	2019-12-22 19:02:07.347978	Don't Let Me Down	182	3	5	171	724	{}
721	2019-12-22 19:02:07.347978	The Ballad Of John & Yoko	182	3	6	171	725	{}
722	2019-12-22 19:02:07.347978	Old Brown Shoe	182	3	7	171	726	{}
723	2019-12-22 19:02:07.347978	Here Comes The Sun	182	4	1	171	727	{}
724	2019-12-22 19:02:07.347978	Come Together	182	4	2	171	728	{}
725	2019-12-22 19:02:07.347978	Something	182	4	3	171	729	{}
726	2019-12-22 19:02:07.347978	Octopus's Garden	182	4	4	171	730	{}
727	2019-12-22 19:02:07.347978	Let It Be	182	4	5	171	731	{}
728	2019-12-22 19:02:07.347978	Across The Universe	182	4	6	171	732	{}
729	2019-12-22 19:02:07.347978	The Long And Winding Road	182	4	7	171	733	{}
730	2019-12-22 19:02:07.347978	Break On Through (To The Other Side)	67	1	1	65	734	{}
731	2019-12-22 19:02:07.347978	Soul Kitchen	67	1	2	65	735	{}
732	2019-12-22 19:02:07.347978	The Crystal Ship	67	1	3	65	736	{}
733	2019-12-22 19:02:07.347978	Twentieth Century Fox	67	1	4	65	737	{}
734	2019-12-22 19:02:07.347978	Alabama Song (Whisky Bar)	67	1	5	65	738	{}
735	2019-12-22 19:02:07.347978	Light My Fire	67	1	6	65	739	{}
736	2019-12-22 19:02:07.347978	Back Door Man	67	2	1	65	740	{}
737	2019-12-22 19:02:07.347978	I Looked At You	67	2	2	65	741	{}
738	2019-12-22 19:02:07.347978	End Of The Night	67	2	3	65	742	{}
739	2019-12-22 19:02:07.347978	Take It As It Comes	67	2	4	65	743	{}
740	2019-12-22 19:02:07.347978	The End	67	2	5	65	744	{}
741	2019-12-22 19:02:07.347978	Rehab	25	1	1	19	745	{}
742	2019-12-22 19:02:07.347978	You Know I'm No Good	25	1	2	19	746	{}
743	2019-12-22 19:02:07.347978	Me & Mr Jones	25	1	3	19	747	{}
744	2019-12-22 19:02:07.347978	Just Friends	25	1	4	19	748	{}
745	2019-12-22 19:02:07.347978	Back To Black	25	1	5	19	749	{}
746	2019-12-22 19:02:07.347978	Love Is A Losing Game	25	1	6	19	750	{}
747	2019-12-22 19:02:07.347978	Tears Dry On Their Own	25	2	1	19	751	{}
748	2019-12-22 19:02:07.347978	Wake Up Alone	25	2	2	19	752	{}
749	2019-12-22 19:02:07.347978	Some Unholy War	25	2	3	19	753	{}
750	2019-12-22 19:02:07.347978	He Can Only Hold Her	25	2	4	19	754	{}
751	2019-12-22 19:02:07.347978	You Know I'm No Good	25	2	5	19	755	{}
752	2019-12-22 19:02:07.347978	The Ties That Bind	194	1	1	177	756	{}
753	2019-12-22 19:02:07.347978	Sherry Darling	194	1	2	177	757	{}
754	2019-12-22 19:02:07.347978	Jackson Cage	194	1	3	177	758	{}
755	2019-12-22 19:02:07.347978	Two Hearts	194	1	4	177	759	{}
756	2019-12-22 19:02:07.347978	Independence Day	194	1	5	177	760	{}
757	2019-12-22 19:02:07.347978	Hungry Heart	194	2	1	177	761	{}
758	2019-12-22 19:02:07.347978	Out In The Street	194	2	2	177	762	{}
759	2019-12-22 19:02:07.347978	Crush On You	194	2	3	177	763	{}
760	2019-12-22 19:02:07.347978	You Can Look (But You Better Not Touch)	194	2	4	177	764	{}
761	2019-12-22 19:02:07.347978	I Wanna Marry You	194	2	5	177	765	{}
762	2019-12-22 19:02:07.347978	The River	194	2	6	177	766	{}
763	2019-12-22 19:02:07.347978	Point Blank	194	3	1	177	767	{}
764	2019-12-22 19:02:07.347978	Cadillac Ranch	194	3	2	177	768	{}
765	2019-12-22 19:02:07.347978	I'm A Rocker	194	3	3	177	769	{}
766	2019-12-22 19:02:07.347978	Fade Away	194	3	4	177	770	{}
767	2019-12-22 19:02:07.347978	Stolen Car	194	3	5	177	771	{}
768	2019-12-22 19:02:07.347978	Ramrod	194	4	1	177	772	{}
769	2019-12-22 19:02:07.347978	The Price You Pay	194	4	2	177	773	{}
770	2019-12-22 19:02:07.347978	Drive All Night	194	4	3	177	774	{}
771	2019-12-22 19:02:07.347978	Wreck On The Highway	194	4	4	177	775	{}
772	2019-12-22 19:02:07.347978	Perth	103	1	1	99	776	{}
773	2019-12-22 19:02:07.347978	Minnesota, WI	103	1	2	99	777	{}
774	2019-12-22 19:02:07.347978	Holocene	103	1	3	99	778	{}
775	2019-12-22 19:02:07.347978	Towers	103	1	4	99	779	{}
776	2019-12-22 19:02:07.347978	Michicant	103	1	5	99	780	{}
777	2019-12-22 19:02:07.347978	Hinnom, TX	103	2	1	99	781	{}
778	2019-12-22 19:02:07.347978	Wash.	103	2	2	99	782	{}
779	2019-12-22 19:02:07.347978	Calgary	103	2	3	99	783	{}
780	2019-12-22 19:02:07.347978	Lisbon, OH	103	2	4	99	784	{}
781	2019-12-22 19:02:07.347978	Beth/Rest	103	2	5	99	785	{}
782	2019-12-22 19:02:07.347978	Minipops 67 (Source Field Mix)	91	1	1	92	786	{}
783	2019-12-22 19:02:07.347978	Xmas_Evet10 (Thanaton3 Mix)	91	1	2	92	787	{}
784	2019-12-22 19:02:07.347978	Produk 29	91	2	1	92	788	{}
785	2019-12-22 19:02:07.347978	4 Bit 9d Api+e+6	91	2	2	92	789	{}
786	2019-12-22 19:02:07.347978	180db_	91	3	1	92	790	{}
787	2019-12-22 19:02:07.347978	Circlont6a (Syrobonkus Mix)	91	3	2	92	791	{}
788	2019-12-22 19:02:07.347978	Fz Pseudotimestretch+e+3	91	4	1	92	792	{}
789	2019-12-22 19:02:07.347978	Circlont14 (Shrymoming Mix)	91	4	2	92	793	{}
790	2019-12-22 19:02:07.347978	Syro U473t8+e (Piezoluminescence Mix)	91	5	1	92	794	{}
791	2019-12-22 19:02:07.347978	Papat4 (Pineal Mix)	91	5	2	92	795	{}
792	2019-12-22 19:02:07.347978	S950tx16wasr10 (Earth Portal Mix)	91	6	1	92	796	{}
793	2019-12-22 19:02:07.347978	Aisatsana	91	6	2	92	797	{}
794	2019-12-22 19:02:07.347978	(Just Like) Starting Over	166	1	1	161	798	{}
795	2019-12-22 19:02:07.347978	Kiss Kiss Kiss	166	1	2	161	799	{}
796	2019-12-22 19:02:07.347978	Cleanup Time	166	1	3	161	800	{}
797	2019-12-22 19:02:07.347978	Give Me Something	166	1	4	161	801	{}
798	2019-12-22 19:02:07.347978	I'm Losing You	166	1	5	161	802	{}
799	2019-12-22 19:02:07.347978	I'm Moving On	166	1	6	161	803	{}
800	2019-12-22 19:02:07.347978	Beautiful Boy (Darling Boy)	166	1	7	161	804	{}
801	2019-12-22 19:02:07.347978	Watching The Wheels	166	2	1	161	805	{}
802	2019-12-22 19:02:07.347978	I'm Your Angel	166	2	2	161	806	{}
803	2019-12-22 19:02:07.347978	Woman	166	2	3	161	807	{}
804	2019-12-22 19:02:07.347978	Beautiful Boys	166	2	4	161	808	{}
805	2019-12-22 19:02:07.347978	Dear Yoko	166	2	5	161	809	{}
806	2019-12-22 19:02:07.347978	Every Man Has A Woman Who Loves Him	166	2	6	161	810	{}
807	2019-12-22 19:02:07.347978	Hard Times Are Over	166	2	7	161	811	{}
808	2019-12-22 19:02:07.347978	21st Century Schizoid Man (Including Mirrors)	63	1	1	59	812	{}
809	2019-12-22 19:02:07.347978	I Talk To The Wind	63	1	2	59	813	{}
810	2019-12-22 19:02:07.347978	Epitaph (Including (A) March For No Reason (B) Tomorrow And Tomorrow)	63	1	3	59	814	{}
811	2019-12-22 19:02:07.347978	Moonchild (Including (A) The Dream (B) The Illusion)	63	2	1	59	815	{}
812	2019-12-22 19:02:07.347978	The Court Of The Crimson King (Including (A) The Return Of The Fire Witch (B) The Dance Of The Puppets)	63	2	2	59	816	{}
813	2019-12-22 19:02:07.347978	Sigh No More	205	1	1	184	817	{}
814	2019-12-22 19:02:07.347978	The Cave	205	1	2	184	818	{}
815	2019-12-22 19:02:07.347978	Winter Winds	205	1	3	184	819	{}
816	2019-12-22 19:02:07.347978	Roll Away Your Stone	205	1	4	184	820	{}
817	2019-12-22 19:02:07.347978	White Blank Page	205	1	5	184	821	{}
818	2019-12-22 19:02:07.347978	I Gave You All	205	1	6	184	822	{}
819	2019-12-22 19:02:07.347978	Little Lion Man	205	2	1	184	823	{}
820	2019-12-22 19:02:07.347978	Timshel	205	2	2	184	824	{}
821	2019-12-22 19:02:07.347978	Thistle & Weeds	205	2	3	184	825	{}
822	2019-12-22 19:02:07.347978	Awake My Soul	205	2	4	184	826	{}
823	2019-12-22 19:02:07.347978	Dust Bowl Dance	205	2	5	184	827	{}
824	2019-12-22 19:02:07.347978	After The Storm	205	2	6	184	828	{}
825	2019-12-22 19:02:07.347978	Spirits In The Material World	80	1	1	83	829	{}
826	2019-12-22 19:02:07.347978	Every Little Thing She Does Is Magic	80	1	2	83	830	{}
827	2019-12-22 19:02:07.347978	Invisible Sun	80	1	3	83	831	{}
828	2019-12-22 19:02:07.347978	Hungry For You (J'Aurais Toujours Faim De Toi)	80	1	4	83	832	{}
829	2019-12-22 19:02:07.347978	Demolition Man	80	1	5	83	833	{}
830	2019-12-22 19:02:07.347978	Too Much Information	80	2	1	83	834	{}
831	2019-12-22 19:02:07.347978	Rehumanize Yourself	80	2	2	83	835	{}
832	2019-12-22 19:02:07.347978	One World (Not Three)	80	2	3	83	836	{}
833	2019-12-22 19:02:07.347978	Omegaman	80	2	4	83	837	{}
834	2019-12-22 19:02:07.347978	Secret Journey	80	2	5	83	838	{}
835	2019-12-22 19:02:07.347978	Darkness	80	2	6	83	839	{}
836	2019-12-22 19:02:07.347978	About A Girl	109	1	1	108	840	{}
837	2019-12-22 19:02:07.347978	Come As You Are	109	1	2	108	841	{}
838	2019-12-22 19:02:07.347978	Jesus Doesn't Want Me For A Sunbeam	109	1	3	108	842	{}
839	2019-12-22 19:02:07.347978	The Man Who Sold The World	109	1	4	108	843	{}
840	2019-12-22 19:02:07.347978	Pennyroyal Tea	109	1	5	108	844	{}
841	2019-12-22 19:02:07.347978	Dumb	109	1	6	108	845	{}
842	2019-12-22 19:02:07.347978	Polly	109	1	7	108	846	{}
843	2019-12-22 19:02:07.347978	On A Plain	109	2	1	108	847	{}
844	2019-12-22 19:02:07.347978	Something In The Way	109	2	2	108	848	{}
845	2019-12-22 19:02:07.347978	Plateau	109	2	3	108	849	{}
846	2019-12-22 19:02:07.347978	Oh Me	109	2	4	108	850	{}
847	2019-12-22 19:02:07.347978	Lake Of Fire	109	2	5	108	851	{}
848	2019-12-22 19:02:07.347978	All Apologies	109	2	6	108	852	{}
849	2019-12-22 19:02:07.347978	Where Did You Sleep Last Night	109	2	7	108	853	{}
850	2019-12-22 19:02:07.347978	Girl From The North Country	74	1	1	79	854	{}
851	2019-12-22 19:02:07.347978	Nashville Skyline Rag	74	1	2	79	855	{}
852	2019-12-22 19:02:07.347978	To Be Alone With You	74	1	3	79	856	{}
853	2019-12-22 19:02:07.347978	I Threw It All Away	74	1	4	79	857	{}
854	2019-12-22 19:02:07.347978	Peggy Day	74	1	5	79	858	{}
855	2019-12-22 19:02:07.347978	Lay Lady Lay	74	2	1	79	859	{}
856	2019-12-22 19:02:07.347978	One More Night	74	2	2	79	860	{}
857	2019-12-22 19:02:07.347978	Tell Me That It Isn't True	74	2	3	79	861	{}
858	2019-12-22 19:02:07.347978	Country Pie	74	2	4	79	862	{}
859	2019-12-22 19:02:07.347978	Tonight I'll Be Staying Here With You	74	2	5	79	863	{}
860	2019-12-22 19:02:07.347978	Magical Mystery Tour	181	1	1	171	864	{}
861	2019-12-22 19:02:07.347978	The Fool On The Hill	181	1	2	171	865	{}
862	2019-12-22 19:02:07.347978	Flying	181	1	3	171	866	{}
863	2019-12-22 19:02:07.347978	Blue Jay Way	181	1	4	171	867	{}
864	2019-12-22 19:02:07.347978	Your Mother Should Know	181	1	5	171	868	{}
865	2019-12-22 19:02:07.347978	I Am The Walrus	181	1	6	171	869	{}
866	2019-12-22 19:02:07.347978	Hello Goodbye	181	2	1	171	870	{}
867	2019-12-22 19:02:07.347978	Strawberry Fields Forever	181	2	2	171	871	{}
868	2019-12-22 19:02:07.347978	Penny Lane	181	2	3	171	872	{}
869	2019-12-22 19:02:07.347978	Baby You're A Rich Man	181	2	4	171	873	{}
870	2019-12-22 19:02:07.347978	All You Need Is Love	181	2	5	171	874	{}
871	2019-12-22 19:02:07.347978	Move Over	150	1	1	143	875	{}
872	2019-12-22 19:02:07.347978	Cry Baby	150	1	2	143	876	{}
873	2019-12-22 19:02:07.347978	A Woman Left Lonely	150	1	3	143	877	{}
874	2019-12-22 19:02:07.347978	Half Moon	150	1	4	143	878	{}
875	2019-12-22 19:02:07.347978	Buried Alive In The Blues	150	1	5	143	879	{}
876	2019-12-22 19:02:07.347978	My Baby	150	2	1	143	880	{}
877	2019-12-22 19:02:07.347978	Me & Bobby McGee	150	2	2	143	881	{}
878	2019-12-22 19:02:07.347978	Mercedes Benz	150	2	3	143	882	{}
879	2019-12-22 19:02:07.347978	Trust Me	150	2	4	143	883	{}
880	2019-12-22 19:02:07.347978	Get It While You Can	150	2	5	143	884	{}
881	2019-12-22 19:02:07.347978	Burn The Witch	22	1	1	17	885	{}
882	2019-12-22 19:02:07.347978	Daydreaming	22	1	2	17	886	{}
883	2019-12-22 19:02:07.347978	Decks Dark	22	2	1	17	887	{}
884	2019-12-22 19:02:07.347978	Desert Island Disk	22	2	2	17	888	{}
885	2019-12-22 19:02:07.347978	Ful Stop	22	2	3	17	889	{}
886	2019-12-22 19:02:07.347978	Glass Eyes	22	3	1	17	890	{}
887	2019-12-22 19:02:07.347978	Identikit	22	3	2	17	891	{}
888	2019-12-22 19:02:07.347978	The Numbers	22	3	3	17	892	{}
889	2019-12-22 19:02:07.347978	Present Tense	22	4	1	17	893	{}
890	2019-12-22 19:02:07.347978	Tinker Tailor Soldier Sailor Rich Man Poor Man Beggar Man Thief	22	4	2	17	894	{}
891	2019-12-22 19:02:07.347978	True Love Waits	22	4	3	17	895	{}
892	2019-12-22 19:02:07.347978	One More Time	14	1	1	15	896	{}
893	2019-12-22 19:02:07.347978	Aerodynamic	14	1	2	15	897	{}
894	2019-12-22 19:02:07.347978	Digital Love	14	1	3	15	898	{}
895	2019-12-22 19:02:07.347978	Harder, Better, Faster, Stronger	14	2	1	15	899	{}
896	2019-12-22 19:02:07.347978	Crescendolls	14	2	2	15	900	{}
897	2019-12-22 19:02:07.347978	Nightvision	14	2	3	15	901	{}
898	2019-12-22 19:02:07.347978	Superheroes	14	2	4	15	902	{}
899	2019-12-22 19:02:07.347978	High Life	14	3	1	15	903	{}
900	2019-12-22 19:02:07.347978	Something About Us	14	3	2	15	904	{}
901	2019-12-22 19:02:07.347978	Voyager	14	3	3	15	905	{}
902	2019-12-22 19:02:07.347978	Veridis Quo	14	3	4	15	906	{}
903	2019-12-22 19:02:07.347978	Short Circuit	14	4	1	15	907	{}
904	2019-12-22 19:02:07.347978	Face To Face	14	4	2	15	908	{}
905	2019-12-22 19:02:07.347978	Too Long	14	4	3	15	909	{}
906	2019-12-22 19:02:07.347978	Mrs. Robinson	132	1	1	128	910	{}
907	2019-12-22 19:02:07.347978	For Emily, Whenever I May Find Her	132	1	2	128	911	{}
908	2019-12-22 19:02:07.347978	The Boxer	132	1	3	128	912	{}
909	2019-12-22 19:02:07.347978	The 59th Street Bridge Song (Feelin' Groovy)	132	1	4	128	913	{}
910	2019-12-22 19:02:07.347978	The Sound Of Silence	132	1	5	128	914	{}
911	2019-12-22 19:02:07.347978	I Am A Rock	132	1	6	128	915	{}
912	2019-12-22 19:02:07.347978	Scarborough Fair / Canticle	132	1	7	128	916	{}
913	2019-12-22 19:02:07.347978	Homeward Bound	132	2	1	128	917	{}
914	2019-12-22 19:02:07.347978	Bridge Over Troubled Water	132	2	2	128	918	{}
915	2019-12-22 19:02:07.347978	America	132	2	3	128	919	{}
916	2019-12-22 19:02:07.347978	Kathy's Song	132	2	4	128	920	{}
917	2019-12-22 19:02:07.347978	El Condor Pasa (If I Could)	132	2	5	128	921	{}
918	2019-12-22 19:02:07.347978	Bookends	132	2	6	128	922	{}
919	2019-12-22 19:02:07.347978	Cecilia	132	2	7	128	923	{}
920	2019-12-22 19:02:07.347978	Orchestral Intro	93	1	1	93	924	{}
921	2019-12-22 19:02:07.347978	Welcome To The World Of The Plastic Beach	93	1	2	6	925	{}
922	2019-12-22 19:02:07.347978	White Flag	93	1	3	105	926	{}
923	2019-12-22 19:02:07.347978	Rhinestone Eyes	93	1	4	93	927	{}
924	2019-12-22 19:02:07.347978	Stylo	93	2	1	1	928	{}
925	2019-12-22 19:02:07.347978	Superfast Jellyfish	93	2	2	199	929	{}
926	2019-12-22 19:02:07.347978	Empire Ants	93	2	3	68	930	{}
927	2019-12-22 19:02:07.347978	Glitter Freeze	93	2	4	168	931	{}
928	2019-12-22 19:02:07.347978	Some Kind Of Nature	93	3	1	122	932	{}
929	2019-12-22 19:02:07.347978	On Melancholy Hill	93	3	2	93	933	{}
930	2019-12-22 19:02:07.347978	Broken	93	3	3	93	934	{}
931	2019-12-22 19:02:07.347978	Sweepstakes	93	3	4	1	935	{}
932	2019-12-22 19:02:07.347978	Plastic Beach	93	4	1	93	936	{}
933	2019-12-22 19:02:07.347978	To Binge	93	4	2	68	937	{}
934	2019-12-22 19:02:07.347978	Cloud Of Unknowing	93	4	3	153	938	{}
935	2019-12-22 19:02:07.347978	Pirate Jet	93	4	4	93	939	{}
936	2019-12-22 19:02:07.347978	Bookends Theme (Instrumental)	131	1	1	128	940	{}
937	2019-12-22 19:02:07.347978	Save The Life Of My Child	131	1	2	128	941	{}
938	2019-12-22 19:02:07.347978	America	131	1	3	128	942	{}
939	2019-12-22 19:02:07.347978	Overs	131	1	4	128	943	{}
940	2019-12-22 19:02:07.347978	Voices Of Old People	131	1	5	128	944	{}
941	2019-12-22 19:02:07.347978	Old Friends	131	1	6	128	945	{}
942	2019-12-22 19:02:07.347978	Bookends Theme	131	1	7	128	946	{}
943	2019-12-22 19:02:07.347978	Fakin' It	131	2	1	128	947	{}
944	2019-12-22 19:02:07.347978	Punky's Dilemma	131	2	2	128	948	{}
945	2019-12-22 19:02:07.347978	Mrs. Robinson (From The Motion Picture "The Graduate")	131	2	3	128	949	{}
946	2019-12-22 19:02:07.347978	A Hazy Shade Of Winter	131	2	4	128	950	{}
947	2019-12-22 19:02:07.347978	At The Zoo	131	2	5	128	951	{}
948	2019-12-22 19:02:07.347978	Missing Pieces	172	1	1	165	952	{}
949	2019-12-22 19:02:07.347978	Sixteen Saltines	172	1	2	165	953	{}
950	2019-12-22 19:02:07.347978	Freedom At 21	172	1	3	165	954	{}
951	2019-12-22 19:02:07.347978	Love Interruption	172	1	4	165	955	{}
952	2019-12-22 19:02:07.347978	Blunderbuss	172	1	5	165	956	{}
953	2019-12-22 19:02:07.347978	Hypocritical Kiss	172	1	6	165	957	{}
954	2019-12-22 19:02:07.347978	Weep Themselves To Sleep	172	1	7	165	958	{}
955	2019-12-22 19:02:07.347978	I'm Shakin'	172	2	1	165	959	{}
956	2019-12-22 19:02:07.347978	Trash Tongue Talker	172	2	2	165	960	{}
957	2019-12-22 19:02:07.347978	Hip (Eponymous) Poor Boy	172	2	3	165	961	{}
958	2019-12-22 19:02:07.347978	I Guess I Should Go To Sleep	172	2	4	165	962	{}
959	2019-12-22 19:02:07.347978	On And On And On	172	2	5	165	963	{}
960	2019-12-22 19:02:07.347978	Take Me With You When You Go	172	2	6	165	964	{}
961	2019-12-22 19:02:07.347978	Volume 1 - The Plan	118	1	2	116	965	{}
962	2019-12-22 19:02:07.347978	Change Of The Guard	118	2	1	116	966	{}
963	2019-12-22 19:02:07.347978	Isabelle 	118	2	2	116	967	{}
964	2019-12-22 19:02:07.347978	Final Thought	118	2	3	116	968	{}
965	2019-12-22 19:02:07.347978	The Next Step	118	3	1	116	969	{}
966	2019-12-22 19:02:07.347978	Askim	118	3	2	116	970	{}
967	2019-12-22 19:02:07.347978	Volume 2 - The Glorious Tale	118	3	3	116	971	{}
968	2019-12-22 19:02:07.347978	The Rhythm Changes	118	4	1	116	972	{}
969	2019-12-22 19:02:07.347978	Leroy And Lanisha	118	4	2	116	973	{}
970	2019-12-22 19:02:07.347978	Re Run	118	4	3	116	974	{}
971	2019-12-22 19:02:07.347978	Miss Understanding	118	5	1	116	975	{}
972	2019-12-22 19:02:07.347978	Henrietta Our Hero	118	5	2	116	976	{}
973	2019-12-22 19:02:07.347978	Seven Prayers	118	5	3	116	977	{}
974	2019-12-22 19:02:07.347978	Cherokee	118	5	4	116	978	{}
975	2019-12-22 19:02:07.347978	Volume 3 - The Historic Repetition	118	5	5	116	979	{}
976	2019-12-22 19:02:07.347978	The Magnificent 7	118	6	1	116	980	{}
977	2019-12-22 19:02:07.347978	Re Run Home	118	6	2	116	981	{}
978	2019-12-22 19:02:07.347978	Malcolm's Theme	118	7	1	116	982	{}
979	2019-12-22 19:02:07.347978	Clair De Lune	118	7	2	116	983	{}
980	2019-12-22 19:02:07.347978	The Message	118	7	3	116	984	{}
981	2019-12-22 19:02:07.347978	Death On Two Legs (Dedicated To ...)	95	1	1	94	985	{}
982	2019-12-22 19:02:07.347978	Lazing On A Sunday Afternoon	95	1	2	94	986	{}
983	2019-12-22 19:02:07.347978	I'm In Love With My Car	95	1	3	94	987	{}
984	2019-12-22 19:02:07.347978	You're My Best Friend	95	1	4	94	988	{}
985	2019-12-22 19:02:07.347978	'39	95	1	5	94	989	{}
986	2019-12-22 19:02:07.347978	Sweet Lady	95	1	6	94	990	{}
987	2019-12-22 19:02:07.347978	Seaside Rendezvous	95	1	7	94	991	{}
988	2019-12-22 19:02:07.347978	The Prophet's Song	95	2	1	94	992	{}
989	2019-12-22 19:02:07.347978	Love Of My Life	95	2	2	94	993	{}
990	2019-12-22 19:02:07.347978	Good Company	95	2	3	94	994	{}
991	2019-12-22 19:02:07.347978	Bohemian Rhapsody	95	2	4	94	995	{}
992	2019-12-22 19:02:07.347978	God Save The Queen	95	2	5	94	996	{}
993	2019-12-22 19:02:07.347978	Burning Down The House	210	1	1	185	997	{}
994	2019-12-22 19:02:07.347978	Making Flippy Floppy	210	1	2	185	998	{}
995	2019-12-22 19:02:07.347978	Girlfriend Is Better	210	1	3	185	999	{}
996	2019-12-22 19:02:07.347978	Slippery People	210	1	4	185	1000	{}
997	2019-12-22 19:02:07.347978	I Get Wild / Wild Gravity	210	1	5	185	1001	{}
998	2019-12-22 19:02:07.347978	Swamp	210	2	1	185	1002	{}
999	2019-12-22 19:02:07.347978	Moon Rocks	210	2	2	185	1003	{}
1000	2019-12-22 19:02:07.347978	Pull Up The Roots	210	2	3	185	1004	{}
1001	2019-12-22 19:02:07.347978	This Must Be The Place (Naive Melody)	210	2	4	185	1005	{}
1002	2019-12-22 19:02:07.347978	Still Crazy After All These Years	168	1	1	162	1006	{}
1003	2019-12-22 19:02:07.347978	My Little Town	168	1	2	162	1007	{}
1004	2019-12-22 19:02:07.347978	I Do It For Your Love	168	1	3	162	1008	{}
1005	2019-12-22 19:02:07.347978	50 Ways To Leave Your Lover	168	1	4	162	1009	{}
1006	2019-12-22 19:02:07.347978	Night Game	168	1	5	162	1010	{}
1007	2019-12-22 19:02:07.347978	Gone At Last	168	2	1	162	1011	{}
1008	2019-12-22 19:02:07.347978	Some Folks Lives Roll Easy	168	2	2	162	1012	{}
1009	2019-12-22 19:02:07.347978	Have A Good Time	168	2	3	162	1013	{}
1010	2019-12-22 19:02:07.347978	You're Kind	168	2	4	162	1014	{}
1011	2019-12-22 19:02:07.347978	Silent Eyes	168	2	5	162	1015	{}
1012	2019-12-22 19:02:07.347978	Hurricane	73	1	1	79	1016	{}
1013	2019-12-22 19:02:07.347978	Isis	73	1	2	79	1017	{}
1014	2019-12-22 19:02:07.347978	Mozambique	73	1	3	79	1018	{}
1015	2019-12-22 19:02:07.347978	One More Cup Of Coffee	73	1	4	79	1019	{}
1016	2019-12-22 19:02:07.347978	Oh, Sister	73	1	5	79	1020	{}
1017	2019-12-22 19:02:07.347978	Joey	73	2	1	79	1021	{}
1018	2019-12-22 19:02:07.347978	Romance In Durango	73	2	2	79	1022	{}
1019	2019-12-22 19:02:07.347978	Black Diamond Bay	73	2	3	79	1023	{}
1020	2019-12-22 19:02:07.347978	Sara	73	2	4	79	1024	{}
1021	2019-12-22 19:02:07.347978	Cherub Rock	119	1	1	117	1025	{}
1022	2019-12-22 19:02:07.347978	Quiet	119	1	2	117	1026	{}
1023	2019-12-22 19:02:07.347978	Today	119	1	3	117	1027	{}
1024	2019-12-22 19:02:07.347978	Hummer	119	1	4	117	1028	{}
1025	2019-12-22 19:02:07.347978	Rocket	119	2	1	117	1029	{}
1026	2019-12-22 19:02:07.347978	Disarm	119	2	2	117	1030	{}
1027	2019-12-22 19:02:07.347978	Soma	119	2	3	117	1031	{}
1028	2019-12-22 19:02:07.347978	Geek U.S.A.	119	3	1	117	1032	{}
1029	2019-12-22 19:02:07.347978	Mayonaise	119	3	2	117	1033	{}
1030	2019-12-22 19:02:07.347978	Spaceboy	119	3	3	117	1034	{}
1031	2019-12-22 19:02:07.347978	Silverfuck	119	4	1	117	1035	{}
1032	2019-12-22 19:02:07.347978	Sweet Sweet	119	4	2	117	1036	{}
1033	2019-12-22 19:02:07.347978	Luna	119	4	3	117	1037	{}
1034	2019-12-22 19:02:07.347978	Everlasting Light	197	1	1	178	1038	{}
1035	2019-12-22 19:02:07.347978	Next Girl	197	1	2	178	1039	{}
1036	2019-12-22 19:02:07.347978	Tighten Up	197	1	3	178	1040	{}
1037	2019-12-22 19:02:07.347978	Howlin' For You	197	1	4	178	1041	{}
1038	2019-12-22 19:02:07.347978	She's Long Gone	197	2	1	178	1042	{}
1039	2019-12-22 19:02:07.347978	Black Mud	197	2	2	178	1043	{}
1040	2019-12-22 19:02:07.347978	The Only One	197	2	3	178	1044	{}
1041	2019-12-22 19:02:07.347978	Too Afraid To Love You	197	2	4	178	1045	{}
1042	2019-12-22 19:02:07.347978	Ten Cent Pistol	197	3	1	178	1046	{}
1043	2019-12-22 19:02:07.347978	Sinister Kid	197	3	2	178	1047	{}
1044	2019-12-22 19:02:07.347978	The Go Getter	197	3	3	178	1048	{}
1045	2019-12-22 19:02:07.347978	I'm Not The One	197	3	4	178	1049	{}
1046	2019-12-22 19:02:07.347978	Unknown Brother	197	4	1	178	1050	{}
1047	2019-12-22 19:02:07.347978	Never Gonna Give You Up	197	4	2	178	1051	{}
1048	2019-12-22 19:02:07.347978	These Days	197	4	3	178	1052	{}
1049	2019-12-22 19:02:07.347978	Everlasting Light	197	5	1	178	1053	{}
1050	2019-12-22 19:02:07.347978	Next Girl	197	5	2	178	1054	{}
1051	2019-12-22 19:02:07.347978	Tighten Up	197	5	3	178	1055	{}
1052	2019-12-22 19:02:07.347978	Howlin' For You	197	5	4	178	1056	{}
1053	2019-12-22 19:02:07.347978	She's Long Gone	197	5	5	178	1057	{}
1054	2019-12-22 19:02:07.347978	Black Mud	197	5	6	178	1058	{}
1055	2019-12-22 19:02:07.347978	The Only One	197	5	7	178	1059	{}
1056	2019-12-22 19:02:07.347978	Too Afraid To Love You	197	5	8	178	1060	{}
1057	2019-12-22 19:02:07.347978	Ten Cent Pistol	197	5	9	178	1061	{}
1058	2019-12-22 19:02:07.347978	Sinister Kid	197	5	10	178	1062	{}
1059	2019-12-22 19:02:07.347978	The Go Getter	197	5	11	178	1063	{}
1060	2019-12-22 19:02:07.347978	I'm Not The One	197	5	12	178	1064	{}
1061	2019-12-22 19:02:07.347978	Unknown Brother	197	5	13	178	1065	{}
1062	2019-12-22 19:02:07.347978	Never Gonna Give You Up	197	5	14	178	1066	{}
1063	2019-12-22 19:02:07.347978	These Days	197	5	15	178	1067	{}
1064	2019-12-22 19:02:07.347978	Hello Again	215	1	1	190	1068	{}
1065	2019-12-22 19:02:07.347978	Looking For Love	215	1	2	190	1069	{}
1066	2019-12-22 19:02:07.347978	Magic	215	1	3	190	1070	{}
1067	2019-12-22 19:02:07.347978	Drive	215	1	4	190	1071	{}
1068	2019-12-22 19:02:07.347978	Stranger Eyes	215	1	5	190	1072	{}
1069	2019-12-22 19:02:07.347978	You Might Think	215	2	1	190	1073	{}
1070	2019-12-22 19:02:07.347978	It's Not The Night	215	2	2	190	1074	{}
1071	2019-12-22 19:02:07.347978	Why Can't I Have You	215	2	3	190	1075	{}
1072	2019-12-22 19:02:07.347978	I Refuse	215	2	4	190	1076	{}
1073	2019-12-22 19:02:07.347978	Heartbeat City	215	2	5	190	1077	{}
1074	2019-12-22 19:02:07.347978	Black Dog	40	1	1	35	1078	{}
1075	2019-12-22 19:02:07.347978	Rock And Roll	40	1	2	35	1079	{}
1076	2019-12-22 19:02:07.347978	The Battle Of Evermore	40	1	3	35	1080	{}
1077	2019-12-22 19:02:07.347978	Stairway To Heaven	40	1	4	35	1081	{}
1078	2019-12-22 19:02:07.347978	Misty Mountain Hop	40	2	1	35	1082	{}
1079	2019-12-22 19:02:07.347978	Four Sticks	40	2	2	35	1083	{}
1080	2019-12-22 19:02:07.347978	Going To California	40	2	3	35	1084	{}
1081	2019-12-22 19:02:07.347978	When The Levee Breaks	40	2	4	35	1085	{}
1082	2019-12-22 19:02:07.347978	Band On The Run	139	1	1	136	1086	{}
1083	2019-12-22 19:02:07.347978	Jet	139	1	2	136	1087	{}
1084	2019-12-22 19:02:07.347978	Bluebird	139	1	3	136	1088	{}
1085	2019-12-22 19:02:07.347978	Mrs. Vandebilt	139	1	4	136	1089	{}
1086	2019-12-22 19:02:07.347978	Let Me Roll It	139	1	5	136	1090	{}
1087	2019-12-22 19:02:07.347978	Mamunia	139	2	1	136	1091	{}
1088	2019-12-22 19:02:07.347978	No Words	139	2	2	136	1092	{}
1089	2019-12-22 19:02:07.347978	Helen Wheels	139	2	3	136	1093	{}
1090	2019-12-22 19:02:07.347978	Picasso's Last Words (Drink To Me)	139	2	4	136	1094	{}
1091	2019-12-22 19:02:07.347978	Nineteen Hundred And Eighty Five	139	2	5	136	1095	{}
1092	2019-12-22 19:02:07.347978	Mysterons	151	1	1	144	1096	{}
1093	2019-12-22 19:02:07.347978	Sour Times	151	1	2	144	1097	{}
1094	2019-12-22 19:02:07.347978	Strangers	151	1	3	144	1098	{}
1095	2019-12-22 19:02:07.347978	It Could Be Sweet	151	1	4	144	1099	{}
1096	2019-12-22 19:02:07.347978	Wandering Star	151	1	5	144	1100	{}
1097	2019-12-22 19:02:07.347978	Numb	151	2	1	144	1101	{}
1098	2019-12-22 19:02:07.347978	Roads	151	2	2	144	1102	{}
1099	2019-12-22 19:02:07.347978	Pedestal	151	2	3	144	1103	{}
1100	2019-12-22 19:02:07.347978	Biscuit	151	2	4	144	1104	{}
1101	2019-12-22 19:02:07.347978	Glory Box	151	2	5	144	1105	{}
1102	2019-12-22 19:02:07.347978	Papa Don't Preach	75	1	1	80	1106	{}
1103	2019-12-22 19:02:07.347978	Open Your Heart	75	1	2	80	1107	{}
1104	2019-12-22 19:02:07.347978	White Heat	75	1	3	80	1108	{}
1105	2019-12-22 19:02:07.347978	Live To Tell	75	1	4	80	1109	{}
1106	2019-12-22 19:02:07.347978	Where's The Party	75	2	1	80	1110	{}
1107	2019-12-22 19:02:07.347978	True Blue	75	2	2	80	1111	{}
1108	2019-12-22 19:02:07.347978	La Isla Bonita	75	2	3	80	1112	{}
1109	2019-12-22 19:02:07.347978	Jimmy Jimmy	75	2	4	80	1113	{}
1110	2019-12-22 19:02:07.347978	Love Makes The World Go Round	75	2	5	80	1114	{}
1111	2019-12-22 19:02:07.347978	Love's In Need Of Love Today	10	1	1	10	1115	{}
1112	2019-12-22 19:02:07.347978	Have A Talk With God	10	1	2	10	1116	{}
1113	2019-12-22 19:02:07.347978	Village Ghetto Land	10	1	3	10	1117	{}
1114	2019-12-22 19:02:07.347978	Contusion	10	1	4	10	1118	{}
1115	2019-12-22 19:02:07.347978	Sir Duke	10	1	5	10	1119	{}
1116	2019-12-22 19:02:07.347978	I Wish	10	2	1	10	1120	{}
1117	2019-12-22 19:02:07.347978	Knocks Me Off My Feet	10	2	2	10	1121	{}
1118	2019-12-22 19:02:07.347978	Pastime Paradise	10	2	3	10	1122	{}
1119	2019-12-22 19:02:07.347978	Summer Soft	10	2	4	10	1123	{}
1120	2019-12-22 19:02:07.347978	Ordinary Pain	10	2	5	10	1124	{}
1121	2019-12-22 19:02:07.347978	Isn't She Lovely	10	3	1	10	1125	{}
1122	2019-12-22 19:02:07.347978	Joy Inside My Tears	10	3	2	10	1126	{}
1123	2019-12-22 19:02:07.347978	Black Man	10	3	3	10	1127	{}
1124	2019-12-22 19:02:07.347978	Ngiculela - Es Una Historia - I Am Singing	10	4	1	10	1128	{}
1125	2019-12-22 19:02:07.347978	If It's Magic	10	4	2	10	1129	{}
1126	2019-12-22 19:02:07.347978	As	10	4	3	10	1130	{}
1127	2019-12-22 19:02:07.347978	Another Star	10	4	4	10	1131	{}
1128	2019-12-22 19:02:07.347978	A Something's Extra Bonus Record	10	4	5	10	1132	{}
1129	2019-12-22 19:02:07.347978	Saturn	10	5	1	10	1133	{}
1130	2019-12-22 19:02:07.347978	Ebony Eyes	10	5	2	10	1134	{}
1131	2019-12-22 19:02:07.347978	All Day Sucker	10	6	1	10	1135	{}
1132	2019-12-22 19:02:07.347978	Easy Goin' Evening (My Mama's Call)	10	6	2	10	1136	{}
1133	2019-12-22 19:02:07.347978	Intro	32	1	1	31	1137	{}
1134	2019-12-22 19:02:07.347978	VCR	32	1	2	31	1138	{}
1135	2019-12-22 19:02:07.347978	Crystalised	32	1	3	31	1139	{}
1136	2019-12-22 19:02:07.347978	Islands	32	1	4	31	1140	{}
1137	2019-12-22 19:02:07.347978	Heart Skipped A Beat	32	1	5	31	1141	{}
1138	2019-12-22 19:02:07.347978	Hot Like Fire	32	1	6	31	1142	{}
1139	2019-12-22 19:02:07.347978	Fantasy	32	2	1	31	1143	{}
1140	2019-12-22 19:02:07.347978	Shelter	32	2	2	31	1144	{}
1141	2019-12-22 19:02:07.347978	Basic Space	32	2	3	31	1145	{}
1142	2019-12-22 19:02:07.347978	Infinity	32	2	4	31	1146	{}
1143	2019-12-22 19:02:07.347978	Night Time	32	2	5	31	1147	{}
1144	2019-12-22 19:02:07.347978	Stars	32	2	6	31	1148	{}
1145	2019-12-22 19:02:07.347978	Easy Money	99	1	1	97	1149	{}
1146	2019-12-22 19:02:07.347978	An Innocent Man	99	1	2	97	1150	{}
1147	2019-12-22 19:02:07.347978	The Longest Time	99	1	3	97	1151	{}
1148	2019-12-22 19:02:07.347978	This Night	99	1	4	97	1152	{}
1149	2019-12-22 19:02:07.347978	Tell Her About It	99	1	5	97	1153	{}
1150	2019-12-22 19:02:07.347978	Uptown Girl	99	2	1	97	1154	{}
1151	2019-12-22 19:02:07.347978	Careless Talk	99	2	2	97	1155	{}
1152	2019-12-22 19:02:07.347978	Christie Lee	99	2	3	97	1156	{}
1153	2019-12-22 19:02:07.347978	Leave A Tender Moment Alone	99	2	4	97	1157	{}
1154	2019-12-22 19:02:07.347978	Keeping The Faith	99	2	5	97	1158	{}
1155	2019-12-22 19:02:07.347978	Pigs On The Wing (Part One)	127	1	1	127	1159	{}
1156	2019-12-22 19:02:07.347978	Dogs	127	1	2	127	1160	{}
1157	2019-12-22 19:02:07.347978	Pigs (Three Different Ones)	127	2	1	127	1161	{}
1158	2019-12-22 19:02:07.347978	Sheep	127	2	2	127	1162	{}
1159	2019-12-22 19:02:07.347978	Pigs On The Wing (Part Two)	127	2	3	127	1163	{}
1160	2019-12-22 19:02:07.347978	The Suburbs	187	1	1	173	1164	{}
1161	2019-12-22 19:02:07.347978	Ready To Start	187	1	2	173	1165	{}
1162	2019-12-22 19:02:07.347978	Modern Man	187	1	3	173	1166	{}
1163	2019-12-22 19:02:07.347978	Rococo	187	1	4	173	1167	{}
1164	2019-12-22 19:02:07.347978	Empty Room	187	2	1	173	1168	{}
1165	2019-12-22 19:02:07.347978	City With No Children	187	2	2	173	1169	{}
1166	2019-12-22 19:02:07.347978	Half Light I	187	2	3	173	1170	{}
1167	2019-12-22 19:02:07.347978	Half Light II (No Celebration)	187	2	4	173	1171	{}
1168	2019-12-22 19:02:07.347978	Month Of May	187	3	1	173	1172	{}
1169	2019-12-22 19:02:07.347978	Wasted Hours	187	3	2	173	1173	{}
1170	2019-12-22 19:02:07.347978	Deep Blue	187	3	3	173	1174	{}
1171	2019-12-22 19:02:07.347978	We Used To Wait	187	3	4	173	1175	{}
1172	2019-12-22 19:02:07.347978	Sprawl I (Flatland)	187	4	1	173	1176	{}
1173	2019-12-22 19:02:07.347978	Sprawl II (Mountains Beyond Mountains)	187	4	2	173	1177	{}
1174	2019-12-22 19:02:07.347978	Suburban War	187	4	3	173	1178	{}
1175	2019-12-22 19:02:07.347978	The Suburbs (Continued)	187	4	4	173	1179	{}
1176	2019-12-22 19:02:07.347978	Sgt. Pepper's Lonely Hearts Club Band	180	1	1	171	1180	{}
1177	2019-12-22 19:02:07.347978	With A Little Help From My Friends	180	1	2	171	1181	{}
1178	2019-12-22 19:02:07.347978	Lucy In The Sky With Diamonds	180	1	3	171	1182	{}
1179	2019-12-22 19:02:07.347978	Getting Better	180	1	4	171	1183	{}
1180	2019-12-22 19:02:07.347978	Fixing A Hole	180	1	5	171	1184	{}
1181	2019-12-22 19:02:07.347978	She's Leaving Home	180	1	6	171	1185	{}
1182	2019-12-22 19:02:07.347978	Being For The Benefit Of Mr. Kite!	180	1	7	171	1186	{}
1183	2019-12-22 19:02:07.347978	Within You Without You	180	2	1	171	1187	{}
1184	2019-12-22 19:02:07.347978	When I'm Sixty-Four	180	2	2	171	1188	{}
1185	2019-12-22 19:02:07.347978	Lovely Rita	180	2	3	171	1189	{}
1186	2019-12-22 19:02:07.347978	Good Morning, Good Morning	180	2	4	171	1190	{}
1187	2019-12-22 19:02:07.347978	Sgt. Pepper's Lonely Hearts Club Band (Reprise)	180	2	5	171	1191	{}
1188	2019-12-22 19:02:07.347978	A Day In The Life	180	2	6	171	1192	{}
1189	2019-12-22 19:02:07.347978	Them Bones	140	1	1	137	1193	{}
1190	2019-12-22 19:02:07.347978	Dam That River	140	1	2	137	1194	{}
1191	2019-12-22 19:02:07.347978	Rain When I Die	140	1	3	137	1195	{}
1192	2019-12-22 19:02:07.347978	Down In A Hole	140	1	4	137	1196	{}
1193	2019-12-22 19:02:07.347978	Sickman	140	1	5	137	1197	{}
1194	2019-12-22 19:02:07.347978	Rooster	140	1	6	137	1198	{}
1195	2019-12-22 19:02:07.347978	Junkhead	140	2	1	137	1199	{}
1196	2019-12-22 19:02:07.347978	Dirt	140	2	2	137	1200	{}
1197	2019-12-22 19:02:07.347978	God Smack	140	2	3	137	1201	{}
1198	2019-12-22 19:02:07.347978	Iron Gland	140	2	4	137	1202	{}
1199	2019-12-22 19:02:07.347978	Hate To Feel	140	2	5	137	1203	{}
1200	2019-12-22 19:02:07.347978	Angry Chair	140	2	6	137	1204	{}
1201	2019-12-22 19:02:07.347978	Would?	140	2	7	137	1205	{}
1202	2019-12-22 19:02:07.347978	My My, Hey Hey (Out Of The Blue)	122	1	1	123	1206	{}
1203	2019-12-22 19:02:07.347978	Thrasher	122	1	2	123	1207	{}
1204	2019-12-22 19:02:07.347978	Ride My Llama	122	1	3	123	1208	{}
1205	2019-12-22 19:02:07.347978	Pocahontas	122	1	4	123	1209	{}
1206	2019-12-22 19:02:07.347978	Sail Away	122	1	5	123	1210	{}
1207	2019-12-22 19:02:07.347978	Powderfinger	122	2	1	123	1211	{}
1208	2019-12-22 19:02:07.347978	Welfare Mothers	122	2	2	123	1212	{}
1209	2019-12-22 19:02:07.347978	Sedan Delivery	122	2	3	123	1213	{}
1210	2019-12-22 19:02:07.347978	Hey Hey, My My (Into The Black)	122	2	4	123	1214	{}
1211	2019-12-22 19:02:07.347978	Bella Donna	70	1	1	71	1215	{}
1212	2019-12-22 19:02:07.347978	Kind Of Woman	70	1	2	71	1216	{}
1213	2019-12-22 19:02:07.347978	Stop Draggin' My Heart Around	70	1	3	71	1217	{}
1214	2019-12-22 19:02:07.347978	Think About It	70	1	4	71	1218	{}
1215	2019-12-22 19:02:07.347978	After The Glitter Fades	70	1	5	71	1219	{}
1216	2019-12-22 19:02:07.347978	Edge Of Seventeen	70	2	1	71	1220	{}
1217	2019-12-22 19:02:07.347978	How Still My Love	70	2	2	71	1221	{}
1218	2019-12-22 19:02:07.347978	Leather And Lace	70	2	3	71	1222	{}
1219	2019-12-22 19:02:07.347978	Outside The Rain	70	2	4	71	1223	{}
1220	2019-12-22 19:02:07.347978	The Highwayman	70	2	5	71	1224	{}
1221	2019-12-22 19:02:07.347978	Running On Empty	71	1	1	72	1225	{}
1222	2019-12-22 19:02:07.347978	The Road	71	1	2	72	1226	{}
1223	2019-12-22 19:02:07.347978	Rosie	71	1	3	72	1227	{}
1224	2019-12-22 19:02:07.347978	You Love The Thunder	71	1	4	72	1228	{}
1225	2019-12-22 19:02:07.347978	Cocaine	71	1	5	72	1229	{}
1226	2019-12-22 19:02:07.347978	Shaky Town	71	2	1	72	1230	{}
1227	2019-12-22 19:02:07.347978	Love Needs A Heart	71	2	2	72	1231	{}
1228	2019-12-22 19:02:07.347978	Nothing But Time	71	2	3	72	1232	{}
1229	2019-12-22 19:02:07.347978	The Load-Out	71	2	4	72	1233	{}
1230	2019-12-22 19:02:07.347978	Stay	71	2	5	72	1234	{}
1231	2019-12-22 19:02:07.347978	Pumpkin And Honey Bunny	61	1	1	13	1235	{}
1232	2019-12-22 19:02:07.347978	Misirlou	61	1	2	40	1236	{}
1233	2019-12-22 19:02:07.347978	Royale With Cheese	61	1	3	69	1237	{}
1234	2019-12-22 19:02:07.347978	Jungle Boogie	61	1	4	188	1238	{}
1235	2019-12-22 19:02:07.347978	Let's Stay Together	61	1	5	41	1239	{}
1236	2019-12-22 19:02:07.347978	Bustin' Surfboards	61	1	6	62	1240	{}
1237	2019-12-22 19:02:07.347978	Lonesome Town	61	1	7	45	1241	{}
1238	2019-12-22 19:02:07.347978	Son Of A Preacher Man	61	1	8	2	1242	{}
1239	2019-12-22 19:02:07.347978	Zed's Dead, Baby	61	1	9	46	1243	{}
1240	2019-12-22 19:02:07.347978	Bullwinkle Part II	61	1	10	133	1244	{}
1241	2019-12-22 19:02:07.347978	Jack Rabbit Slims Twist Contest	61	2	1	47	1245	{}
1242	2019-12-22 19:02:07.347978	You Never Can Tell	61	2	2	70	1246	{}
1243	2019-12-22 19:02:07.347978	Girl, You'll Be A Woman Soon	61	2	3	154	1247	{}
1244	2019-12-22 19:02:07.347978	If Love Is A Red Dress (Hang Me In Rags)	61	2	4	100	1248	{}
1245	2019-12-22 19:02:07.347978	Bring Out The Gimp	61	2	5	33	1249	{}
1246	2019-12-22 19:02:07.347978	Comanche	61	2	6	63	1250	{}
1247	2019-12-22 19:02:07.347978	Flowers On The Wall	61	2	7	155	1251	{}
1248	2019-12-22 19:02:07.347978	Personality Goes A Long Way	61	2	8	64	1252	{}
1249	2019-12-22 19:02:07.347978	Surf Rider	61	2	9	194	1253	{}
1250	2019-12-22 19:02:07.347978	Ezekiel 25:17	61	2	10	91	1254	{}
1251	2019-12-22 19:02:07.347978	Keep Your Eyes Peeled	189	1	1	174	1255	{}
1252	2019-12-22 19:02:07.347978	I Sat By The Ocean	189	1	2	174	1256	{}
1253	2019-12-22 19:02:07.347978	The Vampyre Of Time And Memory	189	1	3	174	1257	{}
1254	2019-12-22 19:02:07.347978	If I Had A Tail	189	2	1	174	1258	{}
1255	2019-12-22 19:02:07.347978	My God Is The Sun	189	2	2	174	1259	{}
1256	2019-12-22 19:02:07.347978	Kalopsia	189	2	3	174	1260	{}
1257	2019-12-22 19:02:07.347978	Fairweather Friends	189	3	1	174	1261	{}
1258	2019-12-22 19:02:07.347978	Smooth Sailing	189	3	2	174	1262	{}
1259	2019-12-22 19:02:07.347978	I Appear Missing	189	4	1	174	1263	{}
1260	2019-12-22 19:02:07.347978	...Like Clockwork	189	4	2	174	1264	{}
1261	2019-12-22 19:02:07.347978	1984	143	1	1	138	1265	{}
1262	2019-12-22 19:02:07.347978	Jump	143	1	2	138	1266	{}
1263	2019-12-22 19:02:07.347978	Panama	143	1	3	138	1267	{}
1264	2019-12-22 19:02:07.347978	Top Jimmy	143	1	4	138	1268	{}
1265	2019-12-22 19:02:07.347978	Drop Dead Legs	143	1	5	138	1269	{}
1266	2019-12-22 19:02:07.347978	Hot For Teacher	143	2	1	138	1270	{}
1267	2019-12-22 19:02:07.347978	I'll Wait	143	2	2	138	1271	{}
1268	2019-12-22 19:02:07.347978	Girl Gone Bad	143	2	3	138	1272	{}
1269	2019-12-22 19:02:07.347978	House Of Pain	143	2	4	138	1273	{}
1270	2019-12-22 19:02:07.347978	Awesome Mix Vol. 1	60	1	2	58	1274	{}
1271	2019-12-22 19:02:07.347978	Hooked On A Feeling	60	2	1	14	1275	{}
1272	2019-12-22 19:02:07.347978	Go All The Way	60	2	2	156	1276	{}
1273	2019-12-22 19:02:07.347978	Spirit In The Sky	60	2	3	77	1277	{}
1274	2019-12-22 19:02:07.347978	Moonage Daydream	60	2	4	50	1278	{}
1275	2019-12-22 19:02:07.347978	Fooled Around And Fell In Love	60	2	5	56	1279	{}
1276	2019-12-22 19:02:07.347978	I Want You Back	60	2	6	114	1280	{}
1277	2019-12-22 19:02:07.347978	I'm Not In Love	60	3	1	78	1281	{}
1278	2019-12-22 19:02:07.347978	Come And Get Your Love	60	3	2	200	1282	{}
1279	2019-12-22 19:02:07.347978	Cherry Bomb	60	3	3	169	1283	{}
1280	2019-12-22 19:02:07.347978	Escape (The Piña Colada Song)	60	3	4	18	1284	{}
1281	2019-12-22 19:02:07.347978	O-o-h Child	60	3	5	119	1285	{}
1282	2019-12-22 19:02:07.347978	Ain't No Mountain High Enough	60	3	6	21	1286	{}
1283	2019-12-22 19:02:07.347978	Original Score By Tyler Bates	60	3	7	58	1287	{}
1284	2019-12-22 19:02:07.347978	The Final Battles Begins	60	4	1	118	1288	{}
1285	2019-12-22 19:02:07.347978	Morag	60	4	2	118	1289	{}
1286	2019-12-22 19:02:07.347978	Everyone’s An Idiot	60	4	3	118	1290	{}
1287	2019-12-22 19:02:07.347978	What A Bunch Of A-Holes	60	4	4	118	1291	{}
1288	2019-12-22 19:02:07.347978	Sacrifice	60	4	5	118	1292	{}
1289	2019-12-22 19:02:07.347978	The New Meat	60	4	6	118	1293	{}
1290	2019-12-22 19:02:07.347978	The Pod Chase	60	4	7	118	1294	{}
1291	2019-12-22 19:02:07.347978	Don’t Mess With My Walkman	60	4	8	118	1295	{}
1292	2019-12-22 19:02:07.347978	Losers (Bonus Track)	60	4	9	118	1296	{}
1293	2019-12-22 19:02:07.347978	The Ballad Of The Nova Corps (Instrumental)	60	5	1	118	1297	{}
1294	2019-12-22 19:02:07.347978	The Kyln Escape	60	5	2	118	1298	{}
1295	2019-12-22 19:02:07.347978	Groot Spores	60	5	3	118	1299	{}
1296	2019-12-22 19:02:07.347978	Guardians United	60	5	4	118	1300	{}
1297	2019-12-22 19:02:07.347978	The Big Blast	60	5	5	118	1301	{}
1298	2019-12-22 19:02:07.347978	Black Tears	60	5	6	118	1302	{}
1299	2019-12-22 19:02:07.347978	A Nova Upgrade	60	5	7	118	1303	{}
1300	2019-12-22 19:02:07.347978	Hanging On The Telephone	11	1	1	11	1304	{}
1301	2019-12-22 19:02:07.347978	One Way Or Another	11	1	2	11	1305	{}
1302	2019-12-22 19:02:07.347978	Picture This	11	1	3	11	1306	{}
1303	2019-12-22 19:02:07.347978	Fade Away And Radiate	11	1	4	11	1307	{}
1304	2019-12-22 19:02:07.347978	Pretty Baby	11	1	5	11	1308	{}
1305	2019-12-22 19:02:07.347978	I Know But I Don't Know	11	1	6	11	1309	{}
1306	2019-12-22 19:02:07.347978	11:59	11	2	1	11	1310	{}
1307	2019-12-22 19:02:07.347978	Will Anything Happen	11	2	2	11	1311	{}
1308	2019-12-22 19:02:07.347978	Sunday Girl	11	2	3	11	1312	{}
1309	2019-12-22 19:02:07.347978	Heart Of Glass	11	2	4	11	1313	{}
1310	2019-12-22 19:02:07.347978	I'm Gonna Love You Too	11	2	5	11	1314	{}
1311	2019-12-22 19:02:07.347978	Just Go Away	11	2	6	11	1315	{}
1312	2019-12-22 19:02:07.347978	Weight Of Love	196	1	1	178	1316	{}
1313	2019-12-22 19:02:07.347978	In Time	196	1	2	178	1317	{}
1314	2019-12-22 19:02:07.347978	Turn Blue	196	1	3	178	1318	{}
1315	2019-12-22 19:02:07.347978	Fever	196	1	4	178	1319	{}
1316	2019-12-22 19:02:07.347978	Year In Review	196	1	5	178	1320	{}
1317	2019-12-22 19:02:07.347978	Bullet In The Brain	196	2	1	178	1321	{}
1318	2019-12-22 19:02:07.347978	It's Up To You Now	196	2	2	178	1322	{}
1319	2019-12-22 19:02:07.347978	Waiting On Words	196	2	3	178	1323	{}
1320	2019-12-22 19:02:07.347978	10 Lovers	196	2	4	178	1324	{}
1321	2019-12-22 19:02:07.347978	In Our Prime	196	2	5	178	1325	{}
1322	2019-12-22 19:02:07.347978	Gotta Get Away	196	2	6	178	1326	{}
1323	2019-12-22 19:02:07.347978	Weight Of Love	196	3	1	178	1327	{}
1324	2019-12-22 19:02:07.347978	In Time	196	3	2	178	1328	{}
1325	2019-12-22 19:02:07.347978	Turn Blue	196	3	3	178	1329	{}
1326	2019-12-22 19:02:07.347978	Fever	196	3	4	178	1330	{}
1327	2019-12-22 19:02:07.347978	Year In Review	196	3	5	178	1331	{}
1328	2019-12-22 19:02:07.347978	Bullet In The Brain	196	3	6	178	1332	{}
1329	2019-12-22 19:02:07.347978	It's Up To You Now	196	3	7	178	1333	{}
1330	2019-12-22 19:02:07.347978	Waiting On Words	196	3	8	178	1334	{}
1331	2019-12-22 19:02:07.347978	10 Lovers	196	3	9	178	1335	{}
1332	2019-12-22 19:02:07.347978	In Our Prime	196	3	10	178	1336	{}
1333	2019-12-22 19:02:07.347978	Gotta Get Away	196	3	11	178	1337	{}
1334	2019-12-22 19:02:07.347978	Purple Haze	191	1	1	175	1338	{}
1335	2019-12-22 19:02:07.347978	Manic Depression	191	1	2	175	1339	{}
1336	2019-12-22 19:02:07.347978	Hey Joe	191	1	3	175	1340	{}
1337	2019-12-22 19:02:07.347978	Love Or Confusion	191	1	4	175	1341	{}
1338	2019-12-22 19:02:07.347978	May This Be Love	191	1	5	175	1342	{}
1339	2019-12-22 19:02:07.347978	I Don't Live Today	191	1	6	175	1343	{}
1340	2019-12-22 19:02:07.347978	The Wind Cries Mary	191	2	1	175	1344	{}
1341	2019-12-22 19:02:07.347978	Fire	191	2	2	175	1345	{}
1342	2019-12-22 19:02:07.347978	Third Stone From The Sun	191	2	3	175	1346	{}
1343	2019-12-22 19:02:07.347978	Foxey Lady	191	2	4	175	1347	{}
1344	2019-12-22 19:02:07.347978	Are You Experienced?	191	2	5	175	1348	{}
1345	2019-12-22 19:02:07.347978	I Should Live In Salt	123	1	1	124	1349	{}
1346	2019-12-22 19:02:07.347978	Demons	123	1	2	124	1350	{}
1347	2019-12-22 19:02:07.347978	Don't Swallow The Cap	123	1	3	124	1351	{}
1348	2019-12-22 19:02:07.347978	Fireproof	123	1	4	124	1352	{}
1349	2019-12-22 19:02:07.347978	Sea Of Love	123	2	1	124	1353	{}
1350	2019-12-22 19:02:07.347978	Heavenfaced	123	2	2	124	1354	{}
1351	2019-12-22 19:02:07.347978	This Is The Last Time	123	2	3	124	1355	{}
1352	2019-12-22 19:02:07.347978	Graceless	123	3	1	124	1356	{}
1353	2019-12-22 19:02:07.347978	Slipped	123	3	2	124	1357	{}
1354	2019-12-22 19:02:07.347978	I Need My Girl	123	3	3	124	1358	{}
1355	2019-12-22 19:02:07.347978	Humiliation	123	4	1	124	1359	{}
1356	2019-12-22 19:02:07.347978	Pink Rabbits	123	4	2	124	1360	{}
1357	2019-12-22 19:02:07.347978	Hard To Find	123	4	3	124	1361	{}
1358	2019-12-22 19:02:07.347978	And She Was	209	1	1	185	1362	{}
1359	2019-12-22 19:02:07.347978	Give Me Back My Name	209	1	2	185	1363	{}
1360	2019-12-22 19:02:07.347978	Creatures Of Love	209	1	3	185	1364	{}
1361	2019-12-22 19:02:07.347978	The Lady Don't Mind	209	1	4	185	1365	{}
1362	2019-12-22 19:02:07.347978	Perfect World	209	1	5	185	1366	{}
1363	2019-12-22 19:02:07.347978	Stay Up Late	209	2	1	185	1367	{}
1364	2019-12-22 19:02:07.347978	Walk It Down	209	2	2	185	1368	{}
1365	2019-12-22 19:02:07.347978	Television Man	209	2	3	185	1369	{}
1366	2019-12-22 19:02:07.347978	Road To Nowhere	209	2	4	185	1370	{}
1367	2019-12-22 19:02:07.347978	Big Shot	98	1	1	97	1371	{}
1368	2019-12-22 19:02:07.347978	Honesty	98	1	2	97	1372	{}
1369	2019-12-22 19:02:07.347978	My Life	98	1	3	97	1373	{}
1370	2019-12-22 19:02:07.347978	Zanzibar	98	1	4	97	1374	{}
1371	2019-12-22 19:02:07.347978	Stiletto	98	2	1	97	1375	{}
1372	2019-12-22 19:02:07.347978	Rosalinda's Eyes	98	2	2	97	1376	{}
1373	2019-12-22 19:02:07.347978	Half A Mile Away	98	2	3	97	1377	{}
1374	2019-12-22 19:02:07.347978	Until The Night	98	2	4	97	1378	{}
1375	2019-12-22 19:02:07.347978	52nd Street	98	2	5	97	1379	{}
1376	2019-12-22 19:02:07.347978	Waiting	81	1	1	84	1380	{}
1377	2019-12-22 19:02:07.347978	Evil Ways	81	1	2	84	1381	{}
1378	2019-12-22 19:02:07.347978	Shades Of Time	81	1	3	84	1382	{}
1379	2019-12-22 19:02:07.347978	Savor	81	1	4	84	1383	{}
1380	2019-12-22 19:02:07.347978	Jingo	81	1	5	84	1384	{}
1381	2019-12-22 19:02:07.347978	Persuasion	81	2	1	84	1385	{}
1382	2019-12-22 19:02:07.347978	Treat	81	2	2	84	1386	{}
1383	2019-12-22 19:02:07.347978	You Just Don't Care	81	2	3	84	1387	{}
1384	2019-12-22 19:02:07.347978	Soul Sacrifice	81	2	4	84	1388	{}
1385	2019-12-22 19:02:07.347978	Good Times Bad Times	39	1	1	35	1389	{}
1386	2019-12-22 19:02:07.347978	Babe I'm Gonna Leave You	39	1	2	35	1390	{}
1387	2019-12-22 19:02:07.347978	You Shook Me	39	1	3	35	1391	{}
1388	2019-12-22 19:02:07.347978	Dazed And Confused	39	1	4	35	1392	{}
1389	2019-12-22 19:02:07.347978	Your Time Is Gonna Come	39	2	1	35	1393	{}
1390	2019-12-22 19:02:07.347978	Black Mountain Side	39	2	2	35	1394	{}
1391	2019-12-22 19:02:07.347978	Communication Breakdown	39	2	3	35	1395	{}
1392	2019-12-22 19:02:07.347978	I Can't Quit You Baby	39	2	4	35	1396	{}
1393	2019-12-22 19:02:07.347978	How Many More Times	39	2	5	35	1397	{}
1394	2019-12-22 19:02:07.347978	Back In The U.S.S.R.	179	1	1	171	1398	{}
1395	2019-12-22 19:02:07.347978	Dear Prudence	179	1	2	171	1399	{}
1396	2019-12-22 19:02:07.347978	Glass Onion	179	1	3	171	1400	{}
1397	2019-12-22 19:02:07.347978	Ob-La-Di, Ob-La-Da	179	1	4	171	1401	{}
1398	2019-12-22 19:02:07.347978	Wild Honey Pie	179	1	5	171	1402	{}
1399	2019-12-22 19:02:07.347978	The Continuing Story Of Bungalow Bill	179	1	6	171	1403	{}
1400	2019-12-22 19:02:07.347978	While My Guitar Gently Weeps	179	1	7	171	1404	{}
1401	2019-12-22 19:02:07.347978	Happiness Is A Warm Gun	179	1	8	171	1405	{}
1402	2019-12-22 19:02:07.347978	Martha My Dear	179	2	1	171	1406	{}
1403	2019-12-22 19:02:07.347978	I'm So Tired	179	2	2	171	1407	{}
1404	2019-12-22 19:02:07.347978	Blackbird	179	2	3	171	1408	{}
1405	2019-12-22 19:02:07.347978	Piggies	179	2	4	171	1409	{}
1406	2019-12-22 19:02:07.347978	Rocky Racoon	179	2	5	171	1410	{}
1407	2019-12-22 19:02:07.347978	Don't Pass Me By	179	2	6	171	1411	{}
1408	2019-12-22 19:02:07.347978	Why Don't We Do It In The Road?	179	2	7	171	1412	{}
1409	2019-12-22 19:02:07.347978	I Will	179	2	8	171	1413	{}
1410	2019-12-22 19:02:07.347978	Julia	179	2	9	171	1414	{}
1411	2019-12-22 19:02:07.347978	Birthday	179	3	1	171	1415	{}
1412	2019-12-22 19:02:07.347978	Yer Blues	179	3	2	171	1416	{}
1413	2019-12-22 19:02:07.347978	Mother Nature's Son	179	3	3	171	1417	{}
1414	2019-12-22 19:02:07.347978	Everybody's Got Something To Hide Except Me And My Monkey	179	3	4	171	1418	{}
1415	2019-12-22 19:02:07.347978	Sexy Sadie	179	3	5	171	1419	{}
1416	2019-12-22 19:02:07.347978	Helter Skelter	179	3	6	171	1420	{}
1417	2019-12-22 19:02:07.347978	Long, Long, Long	179	3	7	171	1421	{}
1418	2019-12-22 19:02:07.347978	Revolution 1	179	4	1	171	1422	{}
1419	2019-12-22 19:02:07.347978	Honey Pie	179	4	2	171	1423	{}
1420	2019-12-22 19:02:07.347978	Savoy Truffle	179	4	3	171	1424	{}
1421	2019-12-22 19:02:07.347978	Cry Baby Cry	179	4	4	171	1425	{}
1422	2019-12-22 19:02:07.347978	Revolution 9	179	4	5	171	1426	{}
1423	2019-12-22 19:02:07.347978	Good Night	179	4	6	171	1427	{}
1424	2019-12-22 19:02:07.347978	She Found Now	169	1	1	163	1428	{}
1425	2019-12-22 19:02:07.347978	Only Tomorrow	169	1	2	163	1429	{}
1426	2019-12-22 19:02:07.347978	Who Sees You	169	1	3	163	1430	{}
1427	2019-12-22 19:02:07.347978	Is This And Yes	169	1	4	163	1431	{}
1428	2019-12-22 19:02:07.347978	If I Am	169	2	1	163	1432	{}
1429	2019-12-22 19:02:07.347978	New You	169	2	2	163	1433	{}
1430	2019-12-22 19:02:07.347978	In Another Way	169	2	3	163	1434	{}
1431	2019-12-22 19:02:07.347978	Nothing Is	169	2	4	163	1435	{}
1432	2019-12-22 19:02:07.347978	Wonder 2	169	2	5	163	1436	{}
1433	2019-12-22 19:02:07.347978	She Found Now	169	3	1	163	1437	{}
1434	2019-12-22 19:02:07.347978	Only Tomorrow	169	3	2	163	1438	{}
1435	2019-12-22 19:02:07.347978	Who Sees You	169	3	3	163	1439	{}
1436	2019-12-22 19:02:07.347978	Is This And Yes	169	3	4	163	1440	{}
1437	2019-12-22 19:02:07.347978	If I Am	169	3	5	163	1441	{}
1438	2019-12-22 19:02:07.347978	New You	169	3	6	163	1442	{}
1439	2019-12-22 19:02:07.347978	In Another Way	169	3	7	163	1443	{}
1440	2019-12-22 19:02:07.347978	Nothing Is	169	3	8	163	1444	{}
1441	2019-12-22 19:02:07.347978	Wonder 2	169	3	9	163	1445	{}
1442	2019-12-22 19:02:07.347978	Wasted Words	135	1	1	130	1446	{}
1443	2019-12-22 19:02:07.347978	Ramblin Man	135	1	2	130	1447	{}
1444	2019-12-22 19:02:07.347978	Come And Go Blues	135	1	3	130	1448	{}
1445	2019-12-22 19:02:07.347978	Jelly Jelly	135	1	4	130	1449	{}
1446	2019-12-22 19:02:07.347978	Southbound	135	2	1	130	1450	{}
1447	2019-12-22 19:02:07.347978	Jessica	135	2	2	130	1451	{}
1448	2019-12-22 19:02:07.347978	Pony Boy	135	2	3	130	1452	{}
1449	2019-12-22 19:02:07.347978	Black Dog	38	1	1	35	1453	{}
1450	2019-12-22 19:02:07.347978	Rock And Roll	38	1	2	35	1454	{}
1451	2019-12-22 19:02:07.347978	The Battle Of Evermore	38	1	3	35	1455	{}
1452	2019-12-22 19:02:07.347978	Stairway To Heaven	38	1	4	35	1456	{}
1453	2019-12-22 19:02:07.347978	Misty Mountain Hop	38	2	1	35	1457	{}
1454	2019-12-22 19:02:07.347978	Four Sticks	38	2	2	35	1458	{}
1455	2019-12-22 19:02:07.347978	Going To California	38	2	3	35	1459	{}
1456	2019-12-22 19:02:07.347978	When The Levee Breaks	38	2	4	35	1460	{}
1457	2019-12-22 19:02:07.347978	Ten	33	1	2	32	1461	{}
1458	2019-12-22 19:02:07.347978	Once	33	2	1	32	1462	{}
1459	2019-12-22 19:02:07.347978	Even Flow	33	2	2	32	1463	{}
1460	2019-12-22 19:02:07.347978	Alive	33	2	3	32	1464	{}
1461	2019-12-22 19:02:07.347978	Why Go	33	2	4	32	1465	{}
1462	2019-12-22 19:02:07.347978	Black	33	2	5	32	1466	{}
1463	2019-12-22 19:02:07.347978	Jeremy	33	2	6	32	1467	{}
1464	2019-12-22 19:02:07.347978	Oceans	33	3	1	32	1468	{}
1465	2019-12-22 19:02:07.347978	Porch	33	3	2	32	1469	{}
1466	2019-12-22 19:02:07.347978	Garden	33	3	3	32	1470	{}
1467	2019-12-22 19:02:07.347978	Deep	33	3	4	32	1471	{}
1468	2019-12-22 19:02:07.347978	Release	33	3	5	32	1472	{}
1469	2019-12-22 19:02:07.347978	Ten Redux	33	3	6	32	1473	{}
1470	2019-12-22 19:02:07.347978	Once	33	4	1	32	1474	{}
1471	2019-12-22 19:02:07.347978	Even Flow	33	4	2	32	1475	{}
1472	2019-12-22 19:02:07.347978	Alive	33	4	3	32	1476	{}
1473	2019-12-22 19:02:07.347978	Why Go	33	4	4	32	1477	{}
1474	2019-12-22 19:02:07.347978	Black	33	4	5	32	1478	{}
1475	2019-12-22 19:02:07.347978	Jeremy	33	4	6	32	1479	{}
1476	2019-12-22 19:02:07.347978	Oceans	33	5	1	32	1480	{}
1477	2019-12-22 19:02:07.347978	Porch	33	5	2	32	1481	{}
1478	2019-12-22 19:02:07.347978	Garden	33	5	3	32	1482	{}
1479	2019-12-22 19:02:07.347978	Deep	33	5	4	32	1483	{}
1480	2019-12-22 19:02:07.347978	Release	33	5	5	32	1484	{}
1481	2019-12-22 19:02:07.347978	The Changeling	66	1	1	65	1485	{}
1482	2019-12-22 19:02:07.347978	Love Her Madly	66	1	2	65	1486	{}
1483	2019-12-22 19:02:07.347978	Been Down So Long	66	1	3	65	1487	{}
1484	2019-12-22 19:02:07.347978	Cars Hiss By My Window	66	1	4	65	1488	{}
1485	2019-12-22 19:02:07.347978	L.A. Woman	66	1	5	65	1489	{}
1486	2019-12-22 19:02:07.347978	L'America	66	2	1	65	1490	{}
1487	2019-12-22 19:02:07.347978	Hyacinth House	66	2	2	65	1491	{}
1488	2019-12-22 19:02:07.347978	Crawling King Snake	66	2	3	65	1492	{}
1489	2019-12-22 19:02:07.347978	The WASP (Texas Radio And The Big Beat)	66	2	4	65	1493	{}
1490	2019-12-22 19:02:07.347978	Riders On The Storm	66	2	5	65	1494	{}
1491	2019-12-22 19:02:07.347978	40 Side North	56	1	2	52	1495	{}
1492	2019-12-22 19:02:07.347978	The Genesis	56	2	1	52	1496	{}
1493	2019-12-22 19:02:07.347978	N.Y. State Of Mind	56	2	2	52	1497	{}
1494	2019-12-22 19:02:07.347978	Life's A Bitch	56	2	3	52	1498	{}
1495	2019-12-22 19:02:07.347978	The World Is Yours	56	2	4	52	1499	{}
1496	2019-12-22 19:02:07.347978	Halftime	56	2	5	52	1500	{}
1497	2019-12-22 19:02:07.347978	41st Side South	56	2	6	52	1501	{}
1498	2019-12-22 19:02:07.347978	Memory Lane (Sittin' In Da Park)	56	3	1	52	1502	{}
1499	2019-12-22 19:02:07.347978	One Love	56	3	2	52	1503	{}
1500	2019-12-22 19:02:07.347978	One Time 4 Your Mind	56	3	3	52	1504	{}
1501	2019-12-22 19:02:07.347978	Represent	56	3	4	52	1505	{}
1502	2019-12-22 19:02:07.347978	It Ain't Hard To Tell	56	3	5	52	1506	{}
1503	2019-12-22 19:02:07.347978	Babylon Sisters	145	1	1	139	1507	{}
1504	2019-12-22 19:02:07.347978	Hey Nineteen	145	1	2	139	1508	{}
1505	2019-12-22 19:02:07.347978	Glamour Profession	145	1	3	139	1509	{}
1506	2019-12-22 19:02:07.347978	Gaucho	145	2	1	139	1510	{}
1507	2019-12-22 19:02:07.347978	Time Out Of Mind	145	2	2	139	1511	{}
1508	2019-12-22 19:02:07.347978	My Rival	145	2	3	139	1512	{}
1509	2019-12-22 19:02:07.347978	Third World Man	145	2	4	139	1513	{}
1510	2019-12-22 19:02:07.347978	Hells Bells	64	1	1	60	1514	{}
1511	2019-12-22 19:02:07.347978	Shoot To Thrill	64	1	2	60	1515	{}
1512	2019-12-22 19:02:07.347978	What Do You Do For Money Honey	64	1	3	60	1516	{}
1513	2019-12-22 19:02:07.347978	Given The Dog A Bone	64	1	4	60	1517	{}
1514	2019-12-22 19:02:07.347978	Let Me Put My Love Into You	64	1	5	60	1518	{}
1515	2019-12-22 19:02:07.347978	Back In Black	64	2	1	60	1519	{}
1516	2019-12-22 19:02:07.347978	You Shook Me All Night Long	64	2	2	60	1520	{}
1517	2019-12-22 19:02:07.347978	Have A Drink On Me	64	2	3	60	1521	{}
1518	2019-12-22 19:02:07.347978	Shake A Leg	64	2	4	60	1522	{}
1519	2019-12-22 19:02:07.347978	Rock And Roll Ain't Noise Pollution	64	2	5	60	1523	{}
1520	2019-12-22 19:02:07.347978	Around The World In  A Day	16	1	1	16	1524	{}
1521	2019-12-22 19:02:07.347978	Paisley Park	16	1	2	16	1525	{}
1522	2019-12-22 19:02:07.347978	Condition Of The Heart	16	1	3	16	1526	{}
1523	2019-12-22 19:02:07.347978	Raspberry Beret	16	1	4	16	1527	{}
1524	2019-12-22 19:02:07.347978	Tamborine	16	1	5	16	1528	{}
1525	2019-12-22 19:02:07.347978	America	16	2	1	16	1529	{}
1526	2019-12-22 19:02:07.347978	Pop Life	16	2	2	16	1530	{}
1527	2019-12-22 19:02:07.347978	The Ladder	16	2	3	16	1531	{}
1528	2019-12-22 19:02:07.347978	Temptation	16	2	4	16	1532	{}
1529	2019-12-22 19:02:07.347978	Space Intro	12	1	1	12	1533	{}
1530	2019-12-22 19:02:07.347978	Fly Like An Eagle	12	1	2	12	1534	{}
1531	2019-12-22 19:02:07.347978	Wild Mountain Honey	12	1	3	12	1535	{}
1532	2019-12-22 19:02:07.347978	Serenade	12	1	4	12	1536	{}
1533	2019-12-22 19:02:07.347978	Dance, Dance, Dance	12	1	5	12	1537	{}
1534	2019-12-22 19:02:07.347978	Mercury Blues	12	1	6	12	1538	{}
1535	2019-12-22 19:02:07.347978	Take The Money And Run	12	2	1	12	1539	{}
1536	2019-12-22 19:02:07.347978	Rock 'N Me	12	2	2	12	1540	{}
1537	2019-12-22 19:02:07.347978	You Send Me	12	2	3	12	1541	{}
1538	2019-12-22 19:02:07.347978	Blue Odyssey	12	2	4	12	1542	{}
1539	2019-12-22 19:02:07.347978	Sweet Maree	12	2	5	12	1543	{}
1540	2019-12-22 19:02:07.347978	The Window	12	2	6	12	1544	{}
1541	2019-12-22 19:02:07.347978	Tangled Up In Blue	72	1	1	79	1545	{}
1542	2019-12-22 19:02:07.347978	Simple Twist Of Fate	72	1	2	79	1546	{}
1543	2019-12-22 19:02:07.347978	You're A Big Girl Now	72	1	3	79	1547	{}
1544	2019-12-22 19:02:07.347978	Idiot Wind	72	1	4	79	1548	{}
1545	2019-12-22 19:02:07.347978	You're Gonna Make Me Lonesome When You Go	72	1	5	79	1549	{}
1546	2019-12-22 19:02:07.347978	Meet Me In The Morning	72	2	1	79	1550	{}
1547	2019-12-22 19:02:07.347978	Lily, Rosemary And The Jack Of Hearts	72	2	2	79	1551	{}
1548	2019-12-22 19:02:07.347978	If You See Her, Say Hello	72	2	3	79	1552	{}
1549	2019-12-22 19:02:07.347978	Shelter From The Storm	72	2	4	79	1553	{}
1550	2019-12-22 19:02:07.347978	Buckets Of Rain	72	2	5	79	1554	{}
1551	2019-12-22 19:02:07.347978	Is This It	8	1	1	8	1555	{}
1552	2019-12-22 19:02:07.347978	The Modern Age	8	1	2	8	1556	{}
1553	2019-12-22 19:02:07.347978	Soma	8	1	3	8	1557	{}
1554	2019-12-22 19:02:07.347978	Barely Legal	8	1	4	8	1558	{}
1555	2019-12-22 19:02:07.347978	Someday	8	1	5	8	1559	{}
1556	2019-12-22 19:02:07.347978	Alone, Together	8	2	1	8	1560	{}
1557	2019-12-22 19:02:07.347978	Last Nite	8	2	2	8	1561	{}
1558	2019-12-22 19:02:07.347978	Hard To Explain	8	2	3	8	1562	{}
1559	2019-12-22 19:02:07.347978	New York City Cops	8	2	4	8	1563	{}
1560	2019-12-22 19:02:07.347978	Trying Your Luck	8	2	5	8	1564	{}
1561	2019-12-22 19:02:07.347978	Take It Or Leave It	8	2	6	8	1565	{}
1562	2019-12-22 19:02:07.347978	One Of These Days	126	1	1	127	1566	{}
1563	2019-12-22 19:02:07.347978	A Pillow Of Winds	126	1	2	127	1567	{}
1564	2019-12-22 19:02:07.347978	Fearless	126	1	3	127	1568	{}
1565	2019-12-22 19:02:07.347978	San Tropez	126	1	4	127	1569	{}
1566	2019-12-22 19:02:07.347978	Seamus	126	1	5	127	1570	{}
1567	2019-12-22 19:02:07.347978	Echoes	126	2	1	127	1571	{}
1568	2019-12-22 19:02:07.347978	Reflektor	186	1	1	173	1572	{}
1569	2019-12-22 19:02:07.347978	Flashbulb Eyes	186	1	2	173	1573	{}
1570	2019-12-22 19:02:07.347978	Here Comes The Night Time	186	1	3	173	1574	{}
1571	2019-12-22 19:02:07.347978	We Exist	186	2	1	173	1575	{}
1572	2019-12-22 19:02:07.347978	Normal Person	186	2	2	173	1576	{}
1573	2019-12-22 19:02:07.347978	You Already Know	186	2	3	173	1577	{}
1574	2019-12-22 19:02:07.347978	Joan Of Arc	186	2	4	173	1578	{}
1575	2019-12-22 19:02:07.347978	Here Comes The Night Time II	186	3	1	173	1579	{}
1576	2019-12-22 19:02:07.347978	Awful Sound (Oh Eurydice)	186	3	2	173	1580	{}
1577	2019-12-22 19:02:07.347978	It's Never Over (Hey Orpheus)	186	3	3	173	1581	{}
1578	2019-12-22 19:02:07.347978	Porno	186	4	1	173	1582	{}
1579	2019-12-22 19:02:07.347978	Afterlife	186	4	2	173	1583	{}
1580	2019-12-22 19:02:07.347978	Supersymmetry	186	4	3	173	1584	{}
1581	2019-12-22 19:02:07.347978	Music Sounds Better With You	26	1	1	24	1585	{}
1582	2019-12-22 19:02:07.347978	Debaser	42	1	1	37	1586	{}
1583	2019-12-22 19:02:07.347978	Tame	42	1	2	37	1587	{}
1584	2019-12-22 19:02:07.347978	Wave Of Mutilation	42	1	3	37	1588	{}
1585	2019-12-22 19:02:07.347978	I Bleed	42	1	4	37	1589	{}
1586	2019-12-22 19:02:07.347978	Here Comes Your Man	42	1	5	37	1590	{}
1587	2019-12-22 19:02:07.347978	Dead	42	1	6	37	1591	{}
1588	2019-12-22 19:02:07.347978	Monkey Gone To Heaven	42	1	7	37	1592	{}
1589	2019-12-22 19:02:07.347978	Mr. Grieves	42	2	1	37	1593	{}
1590	2019-12-22 19:02:07.347978	Crackity Jones	42	2	2	37	1594	{}
1591	2019-12-22 19:02:07.347978	La La Love You	42	2	3	37	1595	{}
1592	2019-12-22 19:02:07.347978	Number 13 Baby	42	2	4	37	1596	{}
1593	2019-12-22 19:02:07.347978	There Goes My Gun	42	2	5	37	1597	{}
1594	2019-12-22 19:02:07.347978	Hey	42	2	6	37	1598	{}
1595	2019-12-22 19:02:07.347978	Silver	42	2	7	37	1599	{}
1596	2019-12-22 19:02:07.347978	Gouge Away	42	2	8	37	1600	{}
1597	2019-12-22 19:02:07.347978	Talkin' Bout A Revolution	96	1	1	95	1601	{}
1598	2019-12-22 19:02:07.347978	Fast Car	96	1	2	95	1602	{}
1599	2019-12-22 19:02:07.347978	Across The Lines	96	1	3	95	1603	{}
1600	2019-12-22 19:02:07.347978	Behind The Wall	96	1	4	95	1604	{}
1601	2019-12-22 19:02:07.347978	Baby Can I Hold You	96	1	5	95	1605	{}
1602	2019-12-22 19:02:07.347978	Mountains O' Things	96	2	1	95	1606	{}
1603	2019-12-22 19:02:07.347978	She's Got Her Ticket	96	2	2	95	1607	{}
1604	2019-12-22 19:02:07.347978	Why?	96	2	3	95	1608	{}
1605	2019-12-22 19:02:07.347978	For My Lover	96	2	4	95	1609	{}
1606	2019-12-22 19:02:07.347978	If Not Now...	96	2	5	95	1610	{}
1607	2019-12-22 19:02:07.347978	For You	96	2	6	95	1611	{}
1608	2019-12-22 19:02:07.347978	Down	112	1	1	110	1612	{}
1609	2019-12-22 19:02:07.347978	Talk To Me	112	1	2	110	1613	{}
1610	2019-12-22 19:02:07.347978	Legend Has It	112	1	3	110	1614	{}
1611	2019-12-22 19:02:07.347978	Call Ticketron	112	1	4	110	1615	{}
1612	2019-12-22 19:02:07.347978	Hey Kids (Bumaye)	112	2	1	110	1616	{}
1613	2019-12-22 19:02:07.347978	Stay Gold	112	2	2	110	1617	{}
1614	2019-12-22 19:02:07.347978	Don't Get Captured	112	2	3	110	1618	{}
1615	2019-12-22 19:02:07.347978	Thieves! (Screamed The Ghost)	112	2	4	110	1619	{}
1616	2019-12-22 19:02:07.347978	2100	112	3	1	110	1620	{}
1617	2019-12-22 19:02:07.347978	Panther Like A Panther (Miracle Mix)	112	3	2	110	1621	{}
1618	2019-12-22 19:02:07.347978	Everybody Stay Calm	112	3	3	110	1622	{}
1619	2019-12-22 19:02:07.347978	Oh Mama	112	4	1	110	1623	{}
1620	2019-12-22 19:02:07.347978	Thursday In The Danger Room	112	4	2	110	1624	{}
1621	2019-12-22 19:02:07.347978	A Report To The Shareholders	112	4	3	110	1625	{}
1622	2019-12-22 19:02:07.347978	Kill Your Masters	112	4	4	110	1626	{}
1623	2019-12-22 19:02:07.347978	Alpha	21	1	2	17	1627	{}
1624	2019-12-22 19:02:07.347978	Everything In Its Right Place	21	2	1	17	1628	{}
1625	2019-12-22 19:02:07.347978	Kid A	21	2	2	17	1629	{}
1626	2019-12-22 19:02:07.347978	Beta	21	2	3	17	1630	{}
1627	2019-12-22 19:02:07.347978	The National Anthem	21	3	1	17	1631	{}
1628	2019-12-22 19:02:07.347978	How To Disappear Completely	21	3	2	17	1632	{}
1629	2019-12-22 19:02:07.347978	Treefingers	21	3	3	17	1633	{}
1630	2019-12-22 19:02:07.347978	Gamma	21	3	4	17	1634	{}
1631	2019-12-22 19:02:07.347978	Optimistic	21	4	1	17	1635	{}
1632	2019-12-22 19:02:07.347978	In Limbo	21	4	2	17	1636	{}
1633	2019-12-22 19:02:07.347978	Delta	21	4	3	17	1637	{}
1634	2019-12-22 19:02:07.347978	Idioteque	21	5	1	17	1638	{}
1635	2019-12-22 19:02:07.347978	Morning Bell	21	5	2	17	1639	{}
1636	2019-12-22 19:02:07.347978	Motion Picture Soundtrack	21	5	3	17	1640	{}
1637	2019-12-22 19:02:07.347978	Synchronicity I	79	1	1	83	1641	{}
1638	2019-12-22 19:02:07.347978	Walking In Your Footsteps	79	1	2	83	1642	{}
1639	2019-12-22 19:02:07.347978	O My God	79	1	3	83	1643	{}
1640	2019-12-22 19:02:07.347978	Mother	79	1	4	83	1644	{}
1641	2019-12-22 19:02:07.347978	Miss Gradenko	79	1	5	83	1645	{}
1642	2019-12-22 19:02:07.347978	Synchronicity II	79	1	6	83	1646	{}
1643	2019-12-22 19:02:07.347978	Every Breath You Take	79	2	1	83	1647	{}
1644	2019-12-22 19:02:07.347978	King Of Pain	79	2	2	83	1648	{}
1645	2019-12-22 19:02:07.347978	Wrapped Around Your Finger	79	2	3	83	1649	{}
1646	2019-12-22 19:02:07.347978	Tea In The Sahara	79	2	4	83	1650	{}
1647	2019-12-22 19:02:07.347978	Daftendirekt	13	1	1	15	1651	{}
1648	2019-12-22 19:02:07.347978	WDPK 83.7 FM	13	1	2	15	1652	{}
1649	2019-12-22 19:02:07.347978	Revolution 909	13	1	3	15	1653	{}
1650	2019-12-22 19:02:07.347978	Da Funk	13	1	4	15	1654	{}
1651	2019-12-22 19:02:07.347978	Phœnix	13	1	5	15	1655	{}
1652	2019-12-22 19:02:07.347978	Fresh	13	2	1	15	1656	{}
1653	2019-12-22 19:02:07.347978	Around The World	13	2	2	15	1657	{}
1654	2019-12-22 19:02:07.347978	Rollin' & Scratchin'	13	2	3	15	1658	{}
1655	2019-12-22 19:02:07.347978	Teachers	13	3	1	15	1659	{}
1656	2019-12-22 19:02:07.347978	High Fidelity	13	3	2	15	1660	{}
1657	2019-12-22 19:02:07.347978	Rock'n Roll	13	3	3	15	1661	{}
1658	2019-12-22 19:02:07.347978	Oh Yeah	13	3	4	15	1662	{}
1659	2019-12-22 19:02:07.347978	Burnin'	13	4	1	15	1663	{}
1660	2019-12-22 19:02:07.347978	Indo Silver Club	13	4	2	15	1664	{}
1661	2019-12-22 19:02:07.347978	Alive	13	4	3	15	1665	{}
1662	2019-12-22 19:02:07.347978	Funk Ad	13	4	4	15	1666	{}
1663	2019-12-22 19:02:07.347978	Changes	52	1	1	50	1667	{}
1664	2019-12-22 19:02:07.347978	Oh! You Pretty Things/Eight Line Poem	52	1	2	50	1668	{}
1665	2019-12-22 19:02:07.347978	Life On Mars?	52	1	3	50	1669	{}
1666	2019-12-22 19:02:07.347978	Kooks	52	1	4	50	1670	{}
1667	2019-12-22 19:02:07.347978	Quicksand	52	1	5	50	1671	{}
1668	2019-12-22 19:02:07.347978	Fill Your Heart/Andy Warhol	52	1	6	50	1672	{}
1669	2019-12-22 19:02:07.347978	Song For Bob Dylan	52	2	1	50	1673	{}
1670	2019-12-22 19:02:07.347978	Queen Bitch	52	2	2	50	1674	{}
1671	2019-12-22 19:02:07.347978	The Bewlay Brothers	52	2	3	50	1675	{}
1672	2019-12-22 19:02:07.347978	Next To You	78	1	1	83	1676	{}
1673	2019-12-22 19:02:07.347978	So Lonely	78	1	2	83	1677	{}
1674	2019-12-22 19:02:07.347978	Roxanne	78	1	3	83	1678	{}
1675	2019-12-22 19:02:07.347978	Hole In My Life	78	1	4	83	1679	{}
1676	2019-12-22 19:02:07.347978	Peanuts	78	1	5	83	1680	{}
1677	2019-12-22 19:02:07.347978	Can't Stand Losing You	78	2	1	83	1681	{}
1678	2019-12-22 19:02:07.347978	Truth Hits Everybody	78	2	2	83	1682	{}
1679	2019-12-22 19:02:07.347978	Born In The 50's	78	2	3	83	1683	{}
1680	2019-12-22 19:02:07.347978	Be My Girl	78	2	4	83	1684	{}
1681	2019-12-22 19:02:07.347978	Sally	78	2	5	83	1685	{}
1682	2019-12-22 19:02:07.347978	Masoko Tanga	78	2	6	83	1686	{}
1683	2019-12-22 19:02:07.347978	Point Of Know Return	156	1	1	149	1687	{}
1684	2019-12-22 19:02:07.347978	Paradox	156	1	2	149	1688	{}
1685	2019-12-22 19:02:07.347978	The Spider	156	1	3	149	1689	{}
1686	2019-12-22 19:02:07.347978	Portrait (He Knew)	156	1	4	149	1690	{}
1687	2019-12-22 19:02:07.347978	Closet Chronicles	156	1	5	149	1691	{}
1688	2019-12-22 19:02:07.347978	Lightning's Hand	156	2	1	149	1692	{}
1689	2019-12-22 19:02:07.347978	Dust In The Wind	156	2	2	149	1693	{}
1690	2019-12-22 19:02:07.347978	Sparks Of The Tempest	156	2	3	149	1694	{}
1691	2019-12-22 19:02:07.347978	Nobody's Home	156	2	4	149	1695	{}
1692	2019-12-22 19:02:07.347978	Hopelessly Human	156	2	5	149	1696	{}
1693	2019-12-22 19:02:07.347978	Refugee	68	1	1	66	1697	{}
1694	2019-12-22 19:02:07.347978	Here Comes My Girl	68	1	2	66	1698	{}
1695	2019-12-22 19:02:07.347978	Even The Losers	68	1	3	66	1699	{}
1696	2019-12-22 19:02:07.347978	Shadow Of A Doubt (A Complex Kid)	68	1	4	66	1700	{}
1697	2019-12-22 19:02:07.347978	Century City	68	1	5	66	1701	{}
1698	2019-12-22 19:02:07.347978	Don't Do Me Like That	68	2	1	66	1702	{}
1699	2019-12-22 19:02:07.347978	You Tell Me	68	2	2	66	1703	{}
1700	2019-12-22 19:02:07.347978	What Are You Doin' In My Life?	68	2	3	66	1704	{}
1701	2019-12-22 19:02:07.347978	Louisiana Rain	68	2	4	66	1705	{}
1702	2019-12-22 19:02:07.347978	We Don't Care	154	1	1	148	1706	{}
1703	2019-12-22 19:02:07.347978	Graduation Day	154	1	2	148	1707	{}
1704	2019-12-22 19:02:07.347978	All Falls Down	154	1	3	148	1708	{}
1705	2019-12-22 19:02:07.347978	Spaceship	154	1	4	148	1709	{}
1706	2019-12-22 19:02:07.347978	Jesus Walks	154	1	5	148	1710	{}
1707	2019-12-22 19:02:07.347978	Never Let Me Down	154	2	1	148	1711	{}
1708	2019-12-22 19:02:07.347978	Get Em High	154	2	2	148	1712	{}
1709	2019-12-22 19:02:07.347978	The New Workout Plan	154	2	3	148	1713	{}
1710	2019-12-22 19:02:07.347978	Through The Wire	154	2	4	148	1714	{}
1711	2019-12-22 19:02:07.347978	Slow Jamz	154	3	1	148	1715	{}
1712	2019-12-22 19:02:07.347978	Breathe In Breathe Out	154	3	2	148	1716	{}
1713	2019-12-22 19:02:07.347978	School Spirit	154	3	3	148	1717	{}
1714	2019-12-22 19:02:07.347978	Two Words	154	3	4	148	1718	{}
1715	2019-12-22 19:02:07.347978	Family Business	154	4	1	148	1719	{}
1716	2019-12-22 19:02:07.347978	Last Call	154	4	2	148	1720	{}
1717	2019-12-22 19:02:07.347978	Variations On A Theme By Erik Satie (1st And 2nd Movements)	152	1	1	145	1721	{}
1718	2019-12-22 19:02:07.347978	Smiling Phases	152	1	2	145	1722	{}
1719	2019-12-22 19:02:07.347978	Sometimes In Winter	152	1	3	145	1723	{}
1720	2019-12-22 19:02:07.347978	More And More	152	1	4	145	1724	{}
1721	2019-12-22 19:02:07.347978	And When I Die	152	1	5	145	1725	{}
1722	2019-12-22 19:02:07.347978	God Bless The Child	152	1	6	145	1726	{}
1723	2019-12-22 19:02:07.347978	Spinning Wheel	152	2	1	145	1727	{}
1724	2019-12-22 19:02:07.347978	You've Made Me So Very Happy	152	2	2	145	1728	{}
1725	2019-12-22 19:02:07.347978	Blues - Part II	152	2	3	145	1729	{}
1726	2019-12-22 19:02:07.347978	Variation On A Theme By Erik Satie (1st Movement)	152	2	4	145	1730	{}
1727	2019-12-22 19:02:07.347978	Black Cow	144	1	1	139	1731	{}
1728	2019-12-22 19:02:07.347978	Aja	144	1	2	139	1732	{}
1729	2019-12-22 19:02:07.347978	Deacon Blues	144	1	3	139	1733	{}
1730	2019-12-22 19:02:07.347978	Peg	144	2	1	139	1734	{}
1731	2019-12-22 19:02:07.347978	Home At Last	144	2	2	139	1735	{}
1732	2019-12-22 19:02:07.347978	I Got The News	144	2	3	139	1736	{}
1733	2019-12-22 19:02:07.347978	Josie	144	2	4	139	1737	{}
1734	2019-12-22 19:02:07.347978	Don't Stand So Close To Me	77	1	1	83	1738	{}
1735	2019-12-22 19:02:07.347978	Driven To Tears	77	1	2	83	1739	{}
1736	2019-12-22 19:02:07.347978	When The World Is Running Down, You Make The Best Of What's Still Around	77	1	3	83	1740	{}
1737	2019-12-22 19:02:07.347978	Canary In A Coalmine	77	1	4	83	1741	{}
1738	2019-12-22 19:02:07.347978	Voices Inside My Head	77	1	5	83	1742	{}
1739	2019-12-22 19:02:07.347978	Bombs Away	77	1	6	83	1743	{}
1740	2019-12-22 19:02:07.347978	De Do Do Do, De Da Da Da	77	2	1	83	1744	{}
1741	2019-12-22 19:02:07.347978	Behind My Camel	77	2	2	83	1745	{}
1742	2019-12-22 19:02:07.347978	Man In A Suitcase	77	2	3	83	1746	{}
1743	2019-12-22 19:02:07.347978	Shadows In The Rain	77	2	4	83	1747	{}
1744	2019-12-22 19:02:07.347978	The Other Way Of Stopping	77	2	5	83	1748	{}
1745	2019-12-22 19:02:07.347978	Opening: I Can't Turn You Loose	76	1	1	81	1749	{}
1746	2019-12-22 19:02:07.347978	Hey Bartender	76	1	2	81	1750	{}
1747	2019-12-22 19:02:07.347978	Messin' With The Kid	76	1	3	81	1751	{}
1748	2019-12-22 19:02:07.347978	(I Got Everything I Need) Almost	76	1	4	81	1752	{}
1749	2019-12-22 19:02:07.347978	Rubber Biscuit	76	1	5	81	1753	{}
1750	2019-12-22 19:02:07.347978	Shot Gun Blues	76	1	6	81	1754	{}
1751	2019-12-22 19:02:07.347978	Groove Me	76	2	1	81	1755	{}
1752	2019-12-22 19:02:07.347978	I Don't Know	76	2	2	81	1756	{}
1753	2019-12-22 19:02:07.347978	Soul Man	76	2	3	81	1757	{}
1754	2019-12-22 19:02:07.347978	"B" Movie Box Car Blues	76	2	4	81	1758	{}
1755	2019-12-22 19:02:07.347978	Flip, Flop & Fly	76	2	5	81	1759	{}
1756	2019-12-22 19:02:07.347978	Closing: I Can't Turn You Loose	76	2	6	81	1760	{}
1757	2019-12-22 19:02:07.347978	Funeral For A Friend/Love Lies Bleeding	49	1	1	48	1761	{}
1758	2019-12-22 19:02:07.347978	Candle In The Wind	49	1	2	48	1762	{}
1759	2019-12-22 19:02:07.347978	Bennie And The Jets	49	1	3	48	1763	{}
1760	2019-12-22 19:02:07.347978	Goodbye Yellow Brick Road	49	2	1	48	1764	{}
1761	2019-12-22 19:02:07.347978	This Song Has No Title	49	2	2	48	1765	{}
1762	2019-12-22 19:02:07.347978	Grey Seal	49	2	3	48	1766	{}
1763	2019-12-22 19:02:07.347978	Jamaica Jerk-off	49	2	4	48	1767	{}
1764	2019-12-22 19:02:07.347978	I've Seen That Movie Too	49	2	5	48	1768	{}
1765	2019-12-22 19:02:07.347978	Sweet Painted Lady	49	3	1	48	1769	{}
1766	2019-12-22 19:02:07.347978	The Ballad Of Danny Bailey (1909-34)	49	3	2	48	1770	{}
1767	2019-12-22 19:02:07.347978	Dirty Little Girl	49	3	3	48	1771	{}
1768	2019-12-22 19:02:07.347978	All The Girls Love Alice	49	3	4	48	1772	{}
1769	2019-12-22 19:02:07.347978	Your Sister Can't Twist (But She Can Rock 'n Roll)	49	4	1	48	1773	{}
1770	2019-12-22 19:02:07.347978	Saturday Night's Alright For Fighting	49	4	2	48	1774	{}
1771	2019-12-22 19:02:07.347978	Roy Rogers	49	4	3	48	1775	{}
1772	2019-12-22 19:02:07.347978	Social Disease	49	4	4	48	1776	{}
1773	2019-12-22 19:02:07.347978	Harmony	49	4	5	48	1777	{}
1774	2019-12-22 19:02:07.347978	Blue Monday	9	1	1	9	1778	{}
1775	2019-12-22 19:02:07.347978	The Beach	9	2	1	9	1779	{}
1776	2019-12-22 19:02:07.347978	Around The World	120	1	1	120	1780	{}
1777	2019-12-22 19:02:07.347978	Parallel Universe	120	1	2	120	1781	{}
1778	2019-12-22 19:02:07.347978	Scar Tissue	120	1	3	120	1782	{}
1779	2019-12-22 19:02:07.347978	Otherside	120	1	4	120	1783	{}
1780	2019-12-22 19:02:07.347978	Get On Top	120	2	1	120	1784	{}
1781	2019-12-22 19:02:07.347978	Californication	120	2	2	120	1785	{}
1782	2019-12-22 19:02:07.347978	Easily	120	2	3	120	1786	{}
1783	2019-12-22 19:02:07.347978	Porcelain	120	3	1	120	1787	{}
1784	2019-12-22 19:02:07.347978	Emit Remmus	120	3	2	120	1788	{}
1785	2019-12-22 19:02:07.347978	I Like Dirt	120	3	3	120	1789	{}
1786	2019-12-22 19:02:07.347978	This Velvet Glove	120	3	4	120	1790	{}
1787	2019-12-22 19:02:07.347978	Savior	120	4	1	120	1791	{}
1788	2019-12-22 19:02:07.347978	Purple Stain	120	4	2	120	1792	{}
1789	2019-12-22 19:02:07.347978	Right On Time	120	4	3	120	1793	{}
1790	2019-12-22 19:02:07.347978	Road Trippin'	120	4	4	120	1794	{}
1791	2019-12-22 19:02:07.347978	Where The Streets Have No Name	171	1	1	164	1795	{}
1792	2019-12-22 19:02:07.347978	I Still Haven't Found What I'm Looking For	171	1	2	164	1796	{}
1793	2019-12-22 19:02:07.347978	With Or Without You	171	1	3	164	1797	{}
1794	2019-12-22 19:02:07.347978	Bullet The Blue Sky	171	1	4	164	1798	{}
1795	2019-12-22 19:02:07.347978	Running To Stand Still	171	1	5	164	1799	{}
1796	2019-12-22 19:02:07.347978	Red Hill Mining Town	171	2	1	164	1800	{}
1797	2019-12-22 19:02:07.347978	In God's Country	171	2	2	164	1801	{}
1798	2019-12-22 19:02:07.347978	Trip Through Your Wires	171	2	3	164	1802	{}
1799	2019-12-22 19:02:07.347978	One Tree Hill	171	2	4	164	1803	{}
1800	2019-12-22 19:02:07.347978	Exit	171	2	5	164	1804	{}
1801	2019-12-22 19:02:07.347978	Mothers Of The Disappeared	171	2	6	164	1805	{}
1802	2019-12-22 19:02:07.347978	Crazy	107	1	1	107	1806	{}
1803	2019-12-22 19:02:07.347978	Put On Your Old Brown Shoes	107	1	2	107	1807	{}
1804	2019-12-22 19:02:07.347978	It's Raining Again	107	1	3	107	1808	{}
1805	2019-12-22 19:02:07.347978	Bonnie	107	1	4	107	1809	{}
1806	2019-12-22 19:02:07.347978	Know Who You Are	107	1	5	107	1810	{}
1807	2019-12-22 19:02:07.347978	My Kind Of Lady	107	2	1	107	1811	{}
1808	2019-12-22 19:02:07.347978	C'est Le Bon	107	2	2	107	1812	{}
1809	2019-12-22 19:02:07.347978	Waiting So Long	107	2	3	107	1813	{}
1810	2019-12-22 19:02:07.347978	Don't Leave Me Now	107	2	4	107	1814	{}
1811	2019-12-22 19:02:07.347978	Immigrant Song	37	1	1	35	1815	{}
1812	2019-12-22 19:02:07.347978	Friends	37	1	2	35	1816	{}
1813	2019-12-22 19:02:07.347978	Celebration Day	37	1	3	35	1817	{}
1814	2019-12-22 19:02:07.347978	Since I've Been Loving You	37	1	4	35	1818	{}
1815	2019-12-22 19:02:07.347978	Out On The Tiles	37	1	5	35	1819	{}
1816	2019-12-22 19:02:07.347978	Gallows Pole	37	2	1	35	1820	{}
1817	2019-12-22 19:02:07.347978	Tangerine	37	2	2	35	1821	{}
1818	2019-12-22 19:02:07.347978	That's The Way	37	2	3	35	1822	{}
1819	2019-12-22 19:02:07.347978	Bron-Y-Aur Stomp	37	2	4	35	1823	{}
1820	2019-12-22 19:02:07.347978	Hats Off To (Roy) Harper	37	2	5	35	1824	{}
1821	2019-12-22 19:02:07.347978	Hollywood Nights	29	1	1	27	1825	{}
1822	2019-12-22 19:02:07.347978	Still The Same	29	1	2	27	1826	{}
1823	2019-12-22 19:02:07.347978	Old Time Rock & Roll	29	1	3	27	1827	{}
1824	2019-12-22 19:02:07.347978	Till It Shines	29	1	4	27	1828	{}
1825	2019-12-22 19:02:07.347978	Feel Like A Number	29	1	5	27	1829	{}
1826	2019-12-22 19:02:07.347978	Ain't Got No Money	29	2	1	27	1830	{}
1827	2019-12-22 19:02:07.347978	We've Got Tonight	29	2	2	27	1831	{}
1828	2019-12-22 19:02:07.347978	Brave Strangers	29	2	3	27	1832	{}
1829	2019-12-22 19:02:07.347978	The Famous Final Scene	29	2	4	27	1833	{}
1830	2019-12-22 19:02:07.347978	Combination Of The Two	164	1	1	159	1834	{}
1831	2019-12-22 19:02:07.347978	I Need A Man To Love	164	1	2	159	1835	{}
1832	2019-12-22 19:02:07.347978	Summertime	164	1	3	159	1836	{}
1833	2019-12-22 19:02:07.347978	Piece Of My Heart	164	1	4	159	1837	{}
1834	2019-12-22 19:02:07.347978	Turtle Blues	164	2	1	159	1838	{}
1835	2019-12-22 19:02:07.347978	Oh, Sweet Mary	164	2	2	159	1839	{}
1836	2019-12-22 19:02:07.347978	Ball And Chain	164	2	3	159	1840	{}
1837	2019-12-22 19:02:07.347978	Planet Telex	20	1	1	17	1841	{}
1838	2019-12-22 19:02:07.347978	The Bends	20	1	2	17	1842	{}
1839	2019-12-22 19:02:07.347978	High And Dry	20	1	3	17	1843	{}
1840	2019-12-22 19:02:07.347978	Fake Plastic Trees	20	1	4	17	1844	{}
1841	2019-12-22 19:02:07.347978	Bones	20	1	5	17	1845	{}
1842	2019-12-22 19:02:07.347978	(Nice Dream)	20	1	6	17	1846	{}
1843	2019-12-22 19:02:07.347978	Just	20	2	1	17	1847	{}
1844	2019-12-22 19:02:07.347978	My Iron Lung	20	2	2	17	1848	{}
1845	2019-12-22 19:02:07.347978	Bullet Proof..I Wish I Was	20	2	3	17	1849	{}
1846	2019-12-22 19:02:07.347978	Black Star	20	2	4	17	1850	{}
1847	2019-12-22 19:02:07.347978	Sulk	20	2	5	17	1851	{}
1848	2019-12-22 19:02:07.347978	Street Spirit (Fade Out)	20	2	6	17	1852	{}
1849	2019-12-22 19:02:07.347978	The Grand Illusion	57	1	1	53	1853	{}
1850	2019-12-22 19:02:07.347978	Fooling Yourself (The Angry Young Man)	57	1	2	53	1854	{}
1851	2019-12-22 19:02:07.347978	Superstars	57	1	3	53	1855	{}
1852	2019-12-22 19:02:07.347978	Come Sail Away	57	1	4	53	1856	{}
1853	2019-12-22 19:02:07.347978	Miss America	57	2	1	53	1857	{}
1854	2019-12-22 19:02:07.347978	Man In The Wilderness	57	2	2	53	1858	{}
1855	2019-12-22 19:02:07.347978	Castle Walls	57	2	3	53	1859	{}
1856	2019-12-22 19:02:07.347978	The Grand Finale	57	2	4	53	1860	{}
1857	2019-12-22 19:02:07.347978	Cycle	211	1	1	186	1861	{}
1858	2019-12-22 19:02:07.347978	Morning	211	1	2	186	1862	{}
1859	2019-12-22 19:02:07.347978	Heart Is A Drum	211	1	3	186	1863	{}
1860	2019-12-22 19:02:07.347978	Say Goodbye	211	1	4	186	1864	{}
1861	2019-12-22 19:02:07.347978	Blue Moon	211	1	5	186	1865	{}
1862	2019-12-22 19:02:07.347978	Unforgiven	211	1	6	186	1866	{}
1863	2019-12-22 19:02:07.347978	Wave	211	2	1	186	1867	{}
1864	2019-12-22 19:02:07.347978	Don't Let It Go	211	2	2	186	1868	{}
1865	2019-12-22 19:02:07.347978	Blackbird Chain	211	2	3	186	1869	{}
1866	2019-12-22 19:02:07.347978	Phase	211	2	4	186	1870	{}
1867	2019-12-22 19:02:07.347978	Turn Away	211	2	5	186	1871	{}
1868	2019-12-22 19:02:07.347978	Country Down	211	2	6	186	1872	{}
1869	2019-12-22 19:02:07.347978	Waking Light	211	2	7	186	1873	{}
1870	2019-12-22 19:02:07.347978	Mladic	89	1	1	90	1874	{}
1871	2019-12-22 19:02:07.347978	We Drift Like Worried Fire	89	2	1	90	1875	{}
1872	2019-12-22 19:02:07.347978	Their Helicopters' Sing	89	3	1	90	1876	{}
1873	2019-12-22 19:02:07.347978	Strung Like Lights At Thee Printemps Erable	89	4	1	90	1877	{}
1874	2019-12-22 19:02:07.347978	Wesley's Theory	213	1	1	189	1878	{}
1875	2019-12-22 19:02:07.347978	For Free? (Interlude)	213	1	2	189	1879	{}
1876	2019-12-22 19:02:07.347978	King Kunta	213	1	3	189	1880	{}
1877	2019-12-22 19:02:07.347978	Institutionalized	213	1	4	189	1881	{}
1878	2019-12-22 19:02:07.347978	These Walls	213	1	5	189	1882	{}
1879	2019-12-22 19:02:07.347978	U	213	2	1	189	1883	{}
1880	2019-12-22 19:02:07.347978	Alright	213	2	2	189	1884	{}
1881	2019-12-22 19:02:07.347978	For Sale? (Interlude)	213	2	3	189	1885	{}
1882	2019-12-22 19:02:07.347978	Momma	213	2	4	189	1886	{}
1883	2019-12-22 19:02:07.347978	Hood Politics	213	3	1	189	1887	{}
1884	2019-12-22 19:02:07.347978	How Much A Dollar Cost	213	3	2	189	1888	{}
1885	2019-12-22 19:02:07.347978	Complexion (A Zulu Love)	213	3	3	189	1889	{}
1886	2019-12-22 19:02:07.347978	The Blacker The Berry	213	3	4	189	1890	{}
1887	2019-12-22 19:02:07.347978	You Ain't Gotta Lie (Momma Said)	213	4	1	189	1891	{}
1888	2019-12-22 19:02:07.347978	I	213	4	2	189	1892	{}
1889	2019-12-22 19:02:07.347978	Mortal Man	213	4	3	189	1893	{}
1890	2019-12-22 19:02:07.347978	Don't Look Back	87	1	1	89	1894	{}
1891	2019-12-22 19:02:07.347978	The Journey	87	1	2	89	1895	{}
1892	2019-12-22 19:02:07.347978	It's Easy	87	1	3	89	1896	{}
1893	2019-12-22 19:02:07.347978	A Man I'll Never Be	87	1	4	89	1897	{}
1894	2019-12-22 19:02:07.347978	Feelin' Satisfied	87	2	1	89	1898	{}
1895	2019-12-22 19:02:07.347978	Party	87	2	2	89	1899	{}
1896	2019-12-22 19:02:07.347978	Used To Bad News	87	2	3	89	1900	{}
1897	2019-12-22 19:02:07.347978	Don't Be Afraid	87	2	4	89	1901	{}
1898	2019-12-22 19:02:07.347978	You're No Good	142	1	1	138	1902	{}
1899	2019-12-22 19:02:07.347978	Dance The Night Away	142	1	2	138	1903	{}
1900	2019-12-22 19:02:07.347978	Somebody Get Me A Doctor	142	1	3	138	1904	{}
1901	2019-12-22 19:02:07.347978	Bottoms Up!	142	1	4	138	1905	{}
1902	2019-12-22 19:02:07.347978	Outta Love Again	142	1	5	138	1906	{}
1903	2019-12-22 19:02:07.347978	Light Up The Sky	142	2	1	138	1907	{}
1904	2019-12-22 19:02:07.347978	Spanish Fly	142	2	2	138	1908	{}
1905	2019-12-22 19:02:07.347978	D.O.A.	142	2	3	138	1909	{}
1906	2019-12-22 19:02:07.347978	Women In Love ...	142	2	4	138	1910	{}
1907	2019-12-22 19:02:07.347978	Beautiful Girls	142	2	5	138	1911	{}
1908	2019-12-22 19:02:07.347978	Stardust	58	1	1	54	1912	{}
1909	2019-12-22 19:02:07.347978	Georgia On My Mind	58	1	2	54	1913	{}
1910	2019-12-22 19:02:07.347978	Blue Skies	58	1	3	54	1914	{}
1911	2019-12-22 19:02:07.347978	All Of Me	58	1	4	54	1915	{}
1912	2019-12-22 19:02:07.347978	Unchained Melody	58	1	5	54	1916	{}
1913	2019-12-22 19:02:07.347978	September Song	58	2	1	54	1917	{}
1914	2019-12-22 19:02:07.347978	On The Sunny Side Of The Street	58	2	2	54	1918	{}
1915	2019-12-22 19:02:07.347978	Moonlight In Vermont	58	2	3	54	1919	{}
1916	2019-12-22 19:02:07.347978	Don't Get Around Much Anymore	58	2	4	54	1920	{}
1917	2019-12-22 19:02:07.347978	Someone To Watch Over Me	58	2	5	54	1921	{}
1918	2019-12-22 19:02:07.347978	Modern Love	51	1	1	50	1922	{}
1919	2019-12-22 19:02:07.347978	China Girl	51	1	2	50	1923	{}
1920	2019-12-22 19:02:07.347978	Let's Dance	51	1	3	50	1924	{}
1921	2019-12-22 19:02:07.347978	Without You	51	1	4	50	1925	{}
1922	2019-12-22 19:02:07.347978	Ricochet	51	2	1	50	1926	{}
1923	2019-12-22 19:02:07.347978	Criminal World	51	2	2	50	1927	{}
1924	2019-12-22 19:02:07.347978	Cat People (Putting Out Fire)	51	2	3	50	1928	{}
1925	2019-12-22 19:02:07.347978	Shake It	51	2	4	50	1929	{}
1926	2019-12-22 19:02:07.347978	ip	19	1	2	17	1930	{}
1927	2019-12-22 19:02:07.347978	Airbag	19	2	1	17	1931	{}
1928	2019-12-22 19:02:07.347978	Paranoid Android	19	2	2	17	1932	{}
1929	2019-12-22 19:02:07.347978	Subterranean Homesick Alien	19	2	3	17	1933	{}
1930	2019-12-22 19:02:07.347978	skip	19	2	4	17	1934	{}
1931	2019-12-22 19:02:07.347978	Exit Music (For A Film)	19	3	1	17	1935	{}
1932	2019-12-22 19:02:07.347978	Let Down	19	3	2	17	1936	{}
1933	2019-12-22 19:02:07.347978	Karma Police	19	3	3	17	1937	{}
1934	2019-12-22 19:02:07.347978	sky	19	3	4	17	1938	{}
1935	2019-12-22 19:02:07.347978	Fitter Happier	19	4	1	17	1939	{}
1936	2019-12-22 19:02:07.347978	Electioneering	19	4	2	17	1940	{}
1937	2019-12-22 19:02:07.347978	Climbing Up The Walls	19	4	3	17	1941	{}
1938	2019-12-22 19:02:07.347978	No Surprises	19	4	4	17	1942	{}
1939	2019-12-22 19:02:07.347978	blue	19	4	5	17	1943	{}
1940	2019-12-22 19:02:07.347978	Lucky	19	5	1	17	1944	{}
1941	2019-12-22 19:02:07.347978	The Tourist	19	5	2	17	1945	{}
1942	2019-12-22 19:02:07.347978	who's	19	5	3	17	1946	{}
1943	2019-12-22 19:02:07.347978	I Promise	19	6	1	17	1947	{}
1944	2019-12-22 19:02:07.347978	Man Of War	19	6	2	17	1948	{}
1945	2019-12-22 19:02:07.347978	Lift	19	6	3	17	1949	{}
1946	2019-12-22 19:02:07.347978	Lull	19	6	4	17	1950	{}
1947	2019-12-22 19:02:07.347978	Meeting In The Aisle	19	6	5	17	1951	{}
1948	2019-12-22 19:02:07.347978	it	19	6	6	17	1952	{}
1949	2019-12-22 19:02:07.347978	Melatonin	19	7	1	17	1953	{}
1950	2019-12-22 19:02:07.347978	A Reminder	19	7	2	17	1954	{}
1951	2019-12-22 19:02:07.347978	Polyethylene (Parts 1 & 2)	19	7	3	17	1955	{}
1952	2019-12-22 19:02:07.347978	Pearly*	19	7	4	17	1956	{}
1953	2019-12-22 19:02:07.347978	Palo Alto	19	7	5	17	1957	{}
1954	2019-12-22 19:02:07.347978	How I Made My Millions	19	7	6	17	1958	{}
1955	2019-12-22 19:02:07.347978	Your Song	48	1	1	48	1959	{}
1956	2019-12-22 19:02:07.347978	Daniel	48	1	2	48	1960	{}
1957	2019-12-22 19:02:07.347978	Honky Cat	48	1	3	48	1961	{}
1958	2019-12-22 19:02:07.347978	Goodbye Yellow Brick Road	48	1	4	48	1962	{}
1959	2019-12-22 19:02:07.347978	Saturday Night's Alright For Fighting	48	1	5	48	1963	{}
1960	2019-12-22 19:02:07.347978	Rocket Man (I Think It's Going To Be A Long Long Time)	48	2	1	48	1964	{}
1961	2019-12-22 19:02:07.347978	Bennie And The Jets	48	2	2	48	1965	{}
1962	2019-12-22 19:02:07.347978	Don't Let The Sun Go Down On Me	48	2	3	48	1966	{}
1963	2019-12-22 19:02:07.347978	Border Song	48	2	4	48	1967	{}
1964	2019-12-22 19:02:07.347978	Crocodile Rock	48	2	5	48	1968	{}
1965	2019-12-22 19:02:07.347978	The View From The Afternoon	176	1	1	167	1969	{}
1966	2019-12-22 19:02:07.347978	I Bet You Look Good On The Dancefloor	176	1	2	167	1970	{}
1967	2019-12-22 19:02:07.347978	Fake Tales Of San Francisco	176	1	3	167	1971	{}
1968	2019-12-22 19:02:07.347978	Dancing Shoes	176	1	4	167	1972	{}
1969	2019-12-22 19:02:07.347978	You Probably Couldn't See For The Lights But You Were Staring Straight At Me	176	1	5	167	1973	{}
1970	2019-12-22 19:02:07.347978	Still Take You Home	176	1	6	167	1974	{}
1971	2019-12-22 19:02:07.347978	Riot Van	176	2	1	167	1975	{}
1972	2019-12-22 19:02:07.347978	Red Light Indicates Doors Are Secured	176	2	2	167	1976	{}
1973	2019-12-22 19:02:07.347978	Mardy Bum	176	2	3	167	1977	{}
1974	2019-12-22 19:02:07.347978	Perhaps Vampires Is A Bit Strong But..	176	2	4	167	1978	{}
1975	2019-12-22 19:02:07.347978	When The Sun Goes Down	176	2	5	167	1979	{}
1976	2019-12-22 19:02:07.347978	From The Ritz To The Rubble	176	2	6	167	1980	{}
1977	2019-12-22 19:02:07.347978	A Certain Romance	176	2	7	167	1981	{}
1978	2019-12-22 19:02:07.347978	The First Song	146	1	1	140	1982	{}
1979	2019-12-22 19:02:07.347978	Wicked Gil	146	1	2	140	1983	{}
1980	2019-12-22 19:02:07.347978	Our Swords	146	1	3	140	1984	{}
1981	2019-12-22 19:02:07.347978	The Funeral	146	1	4	140	1985	{}
1982	2019-12-22 19:02:07.347978	Part One	146	1	5	140	1986	{}
1983	2019-12-22 19:02:07.347978	The Great Salt Lake	146	2	1	140	1987	{}
1984	2019-12-22 19:02:07.347978	Weed Party	146	2	2	140	1988	{}
1985	2019-12-22 19:02:07.347978	I Go To The Barn Because I Like The	146	2	3	140	1989	{}
1986	2019-12-22 19:02:07.347978	Monsters	146	2	4	140	1990	{}
1987	2019-12-22 19:02:07.347978	St. Augustine	146	2	5	140	1991	{}
1988	2019-12-22 19:02:07.347978	To All The Girls	69	1	1	67	1992	{}
1989	2019-12-22 19:02:07.347978	Shake Your Rump	69	1	2	67	1993	{}
1990	2019-12-22 19:02:07.347978	Johnny Ryall	69	1	3	67	1994	{}
1991	2019-12-22 19:02:07.347978	Egg Man	69	1	4	67	1995	{}
1992	2019-12-22 19:02:07.347978	High Plains Drifter	69	1	5	67	1996	{}
1993	2019-12-22 19:02:07.347978	The Sounds Of Science	69	1	6	67	1997	{}
1994	2019-12-22 19:02:07.347978	3-Minute Rule	69	1	7	67	1998	{}
1995	2019-12-22 19:02:07.347978	Hey Ladies	69	1	8	67	1999	{}
1996	2019-12-22 19:02:07.347978	5-Piece Chicken Dinner	69	2	1	67	2000	{}
1997	2019-12-22 19:02:07.347978	Looking Down The Barrel Of A Gun	69	2	2	67	2001	{}
1998	2019-12-22 19:02:07.347978	Car Thief	69	2	3	67	2002	{}
1999	2019-12-22 19:02:07.347978	What Comes Around	69	2	4	67	2003	{}
2000	2019-12-22 19:02:07.347978	Shadrach	69	2	5	67	2004	{}
2001	2019-12-22 19:02:07.347978	Ask For Janice	69	2	6	67	2005	{}
2002	2019-12-22 19:02:07.347978	B-Boy Bouillabaisse	69	2	7	67	2006	{}
2003	2019-12-22 19:02:07.347978	Montezuma	159	1	1	157	2007	{}
2004	2019-12-22 19:02:07.347978	Bedouin Dress	159	1	2	157	2008	{}
2005	2019-12-22 19:02:07.347978	Sim Sala Bim	159	1	3	157	2009	{}
2006	2019-12-22 19:02:07.347978	Battery Kinzie	159	2	1	157	2010	{}
2007	2019-12-22 19:02:07.347978	The Plains / Bitter Dancer	159	2	2	157	2011	{}
2008	2019-12-22 19:02:07.347978	Helplessness Blues	159	2	3	157	2012	{}
2009	2019-12-22 19:02:07.347978	The Cascades	159	3	1	157	2013	{}
2010	2019-12-22 19:02:07.347978	Lorelai	159	3	2	157	2014	{}
2011	2019-12-22 19:02:07.347978	Someone You'd Admire	159	3	3	157	2015	{}
2012	2019-12-22 19:02:07.347978	The Shrine / An Argument	159	4	1	157	2016	{}
2013	2019-12-22 19:02:07.347978	Blue Spotted Tail	159	4	2	157	2017	{}
2014	2019-12-22 19:02:07.347978	Grown Ocean	159	4	3	157	2018	{}
2015	2019-12-22 19:02:07.347978	Psycho Killer	208	1	1	185	2019	{}
2016	2019-12-22 19:02:07.347978	Swamp	208	1	2	185	2020	{}
2017	2019-12-22 19:02:07.347978	Slippery People	208	1	3	185	2021	{}
2018	2019-12-22 19:02:07.347978	Burning Down The House	208	1	4	185	2022	{}
2019	2019-12-22 19:02:07.347978	Girlfriend Is Better	208	1	5	185	2023	{}
2020	2019-12-22 19:02:07.347978	Once In A Lifetime	208	2	1	185	2024	{}
2021	2019-12-22 19:02:07.347978	What A Day That Was	208	2	2	185	2025	{}
2022	2019-12-22 19:02:07.347978	Life During Wartime	208	2	3	185	2026	{}
2023	2019-12-22 19:02:07.347978	Take Me To The River	208	2	4	185	2027	{}
2024	2019-12-22 19:02:07.347978	Bat Out Of Hell	97	1	1	96	2028	{}
2025	2019-12-22 19:02:07.347978	You Took The Words Right Out Of My Mouth (Hot Summer Night)	97	1	2	96	2029	{}
2026	2019-12-22 19:02:07.347978	Heaven Can Wait	97	1	3	96	2030	{}
2027	2019-12-22 19:02:07.347978	All Revved Up With No Place To Go	97	1	4	96	2031	{}
2028	2019-12-22 19:02:07.347978	Two Out Of Three Ain't Bad	97	2	1	96	2032	{}
2029	2019-12-22 19:02:07.347978	Paradise By The Dashboard Light	97	2	2	96	2033	{}
2030	2019-12-22 19:02:07.347978	For Crying Out Loud	97	2	3	96	2034	{}
2031	2019-12-22 19:02:07.347978	Rolling In The Deep	105	1	1	101	2035	{}
2032	2019-12-22 19:02:07.347978	Rumour Has It	105	1	2	101	2036	{}
2033	2019-12-22 19:02:07.347978	Turning Tables	105	1	3	101	2037	{}
2034	2019-12-22 19:02:07.347978	Don't You Remember	105	1	4	101	2038	{}
2035	2019-12-22 19:02:07.347978	Set Fire To The Rain	105	1	5	101	2039	{}
2036	2019-12-22 19:02:07.347978	He Won't Go	105	1	6	101	2040	{}
2037	2019-12-22 19:02:07.347978	Take It All	105	2	1	101	2041	{}
2038	2019-12-22 19:02:07.347978	I'll Be Waiting	105	2	2	101	2042	{}
2039	2019-12-22 19:02:07.347978	One And Only	105	2	3	101	2043	{}
2040	2019-12-22 19:02:07.347978	Lovesong	105	2	4	101	2044	{}
2041	2019-12-22 19:02:07.347978	Someone Like You	105	2	5	101	2045	{}
2042	2019-12-22 19:02:07.347978	Over & Over	35	1	1	34	2046	{}
2043	2019-12-22 19:02:07.347978	The Ledge	35	1	2	34	2047	{}
2044	2019-12-22 19:02:07.347978	Think About Me	35	1	3	34	2048	{}
2045	2019-12-22 19:02:07.347978	Save Me A Place	35	1	4	34	2049	{}
2046	2019-12-22 19:02:07.347978	Sara	35	1	5	34	2050	{}
2047	2019-12-22 19:02:07.347978	What Makes You Think You're The One	35	2	1	34	2051	{}
2048	2019-12-22 19:02:07.347978	Storms	35	2	2	34	2052	{}
2049	2019-12-22 19:02:07.347978	That's All For Everyone	35	2	3	34	2053	{}
2050	2019-12-22 19:02:07.347978	Not That Funny	35	2	4	34	2054	{}
2051	2019-12-22 19:02:07.347978	Sisters Of The Moon	35	2	5	34	2055	{}
2052	2019-12-22 19:02:07.347978	Angel	35	3	1	34	2056	{}
2053	2019-12-22 19:02:07.347978	That's Enough For Me	35	3	2	34	2057	{}
2054	2019-12-22 19:02:07.347978	Brown Eyes	35	3	3	34	2058	{}
2055	2019-12-22 19:02:07.347978	Never Make Me Cry	35	3	4	34	2059	{}
2056	2019-12-22 19:02:07.347978	I Know I'm Not Wrong	35	3	5	34	2060	{}
2057	2019-12-22 19:02:07.347978	Honey Hi	35	4	1	34	2061	{}
2058	2019-12-22 19:02:07.347978	Beautiful Child	35	4	2	34	2062	{}
2059	2019-12-22 19:02:07.347978	Walk A Thin Line	35	4	3	34	2063	{}
2060	2019-12-22 19:02:07.347978	Tusk	35	4	4	34	2064	{}
2061	2019-12-22 19:02:07.347978	Never Forget	35	4	5	34	2065	{}
2062	2019-12-22 19:02:07.347978	Stayin' Alive	59	1	1	22	2066	{}
2063	2019-12-22 19:02:07.347978	How Deep Is Your Love	59	1	2	22	2067	{}
2064	2019-12-22 19:02:07.347978	Night Fever	59	1	3	22	2068	{}
2065	2019-12-22 19:02:07.347978	More Than A Woman	59	1	4	22	2069	{}
2066	2019-12-22 19:02:07.347978	If I Can't Have You	59	1	5	106	2070	{}
2067	2019-12-22 19:02:07.347978	A Fifth Of Beethoven	59	2	1	195	2071	{}
2068	2019-12-22 19:02:07.347978	More Than A Woman	59	2	2	134	2072	{}
2069	2019-12-22 19:02:07.347978	Manhattan Skyline	59	2	3	82	2073	{}
2070	2019-12-22 19:02:07.347978	Calypso Breakdown	59	2	4	23	2074	{}
2071	2019-12-22 19:02:07.347978	Night On Disco Mountain	59	3	1	82	2075	{}
2072	2019-12-22 19:02:07.347978	Open Sesame	59	3	2	188	2076	{}
2073	2019-12-22 19:02:07.347978	Jive Talkin' (Live)	59	3	3	22	2077	{}
2074	2019-12-22 19:02:07.347978	You Should Be Dancing	59	3	4	22	2078	{}
2075	2019-12-22 19:02:07.347978	Boogie Shoes	59	3	5	29	2079	{}
2076	2019-12-22 19:02:07.347978	Salsation	59	4	1	82	2080	{}
2077	2019-12-22 19:02:07.347978	K-Jee	59	4	2	57	2081	{}
2078	2019-12-22 19:02:07.347978	Disco Inferno	59	4	3	201	2082	{}
2079	2019-12-22 19:02:07.347978	Wildlife Analysis	199	1	1	179	2083	{}
2080	2019-12-22 19:02:07.347978	An Eagle In Your Mind	199	1	2	179	2084	{}
2081	2019-12-22 19:02:07.347978	The Color Of The Fire	199	1	3	179	2085	{}
2082	2019-12-22 19:02:07.347978	Telephasic Workshop	199	1	4	179	2086	{}
2083	2019-12-22 19:02:07.347978	Triangles And Rhombuses	199	1	5	179	2087	{}
2084	2019-12-22 19:02:07.347978	Sixtyten	199	2	1	179	2088	{}
2085	2019-12-22 19:02:07.347978	Turquoise Hexagon Sun	199	2	2	179	2089	{}
2086	2019-12-22 19:02:07.347978	Kaini Industries	199	2	3	179	2090	{}
2087	2019-12-22 19:02:07.347978	Bocuma	199	2	4	179	2091	{}
2088	2019-12-22 19:02:07.347978	Roygbiv	199	2	5	179	2092	{}
2089	2019-12-22 19:02:07.347978	Rue The Whirl	199	3	1	179	2093	{}
2090	2019-12-22 19:02:07.347978	Aquarius	199	3	2	179	2094	{}
2091	2019-12-22 19:02:07.347978	Olson	199	3	3	179	2095	{}
2092	2019-12-22 19:02:07.347978	Pete Standing Alone	199	4	1	179	2096	{}
2093	2019-12-22 19:02:07.347978	Smokes Quantity	199	4	2	179	2097	{}
2094	2019-12-22 19:02:07.347978	Open The Light	199	4	3	179	2098	{}
2095	2019-12-22 19:02:07.347978	One Very Important Thought	199	4	4	179	2099	{}
2096	2019-12-22 19:02:07.347978	Be Above It	114	1	1	111	2100	{}
2097	2019-12-22 19:02:07.347978	Endors Toi	114	1	2	111	2101	{}
2098	2019-12-22 19:02:07.347978	Apocalypse Dreams	114	1	3	111	2102	{}
2099	2019-12-22 19:02:07.347978	Mind Mischief	114	2	1	111	2103	{}
2100	2019-12-22 19:02:07.347978	Music To Walk Home By	114	2	2	111	2104	{}
2101	2019-12-22 19:02:07.347978	Why Won't They Talk To Me?	114	2	3	111	2105	{}
2102	2019-12-22 19:02:07.347978	Feels Like We Only Go Backwards	114	3	1	111	2106	{}
2103	2019-12-22 19:02:07.347978	Keep On Lying	114	3	2	111	2107	{}
2104	2019-12-22 19:02:07.347978	Elephant	114	3	3	111	2108	{}
2105	2019-12-22 19:02:07.347978	She Just Won't Believe Me	114	4	1	111	2109	{}
2106	2019-12-22 19:02:07.347978	Nothing That Has Happened So Far Has Been Anything We Could Control	114	4	2	111	2110	{}
2107	2019-12-22 19:02:07.347978	Sun's Coming Up	114	4	3	111	2111	{}
2108	2019-12-22 19:02:07.347978	Ramble Tamble	185	1	1	172	2112	{}
2109	2019-12-22 19:02:07.347978	Before You Accuse Me	185	1	2	172	2113	{}
2110	2019-12-22 19:02:07.347978	Travelin' Band	185	1	3	172	2114	{}
2111	2019-12-22 19:02:07.347978	Ooby Dooby	185	1	4	172	2115	{}
2112	2019-12-22 19:02:07.347978	Lookin' Out My Back Door	185	1	5	172	2116	{}
2113	2019-12-22 19:02:07.347978	Run Through The Jungle	185	1	6	172	2117	{}
2114	2019-12-22 19:02:07.347978	Up Around The Bend	185	2	1	172	2118	{}
2115	2019-12-22 19:02:07.347978	My Baby Left Me	185	2	2	172	2119	{}
2116	2019-12-22 19:02:07.347978	Who'll Stop The Rain	185	2	3	172	2120	{}
2117	2019-12-22 19:02:07.347978	I Heard It Through The Grapevine	185	2	4	172	2121	{}
2118	2019-12-22 19:02:07.347978	Long As I Can See The Light	185	2	5	172	2122	{}
2119	2019-12-22 19:02:07.347978	Twin Peaks Theme	106	1	1	102	2123	{}
2120	2019-12-22 19:02:07.347978	Laura Palmer's Theme	106	1	2	102	2124	{}
2121	2019-12-22 19:02:07.347978	Audrey's Dance	106	1	3	102	2125	{}
2122	2019-12-22 19:02:07.347978	The Nightingale	106	1	4	102	2126	{}
2123	2019-12-22 19:02:07.347978	Freshly Squeezed	106	1	5	102	2127	{}
2124	2019-12-22 19:02:07.347978	The Bookhouse Boys	106	2	1	102	2128	{}
2125	2019-12-22 19:02:07.347978	Into The Night	106	2	2	102	2129	{}
2126	2019-12-22 19:02:07.347978	Night Life In Twin Peaks	106	2	3	102	2130	{}
2127	2019-12-22 19:02:07.347978	Dance Of The Dream Man	106	2	4	102	2131	{}
2128	2019-12-22 19:02:07.347978	Love Theme From Twin Peaks	106	2	5	102	2132	{}
2129	2019-12-22 19:02:07.347978	Falling	106	2	6	102	2133	{}
2130	2019-12-22 19:02:07.347978	Don't Let Him Go	201	1	1	180	2134	{}
2131	2019-12-22 19:02:07.347978	Keep On Loving You	201	1	2	180	2135	{}
2132	2019-12-22 19:02:07.347978	Follow My Heart	201	1	3	180	2136	{}
2133	2019-12-22 19:02:07.347978	In Your Letter	201	1	4	180	2137	{}
2134	2019-12-22 19:02:07.347978	Take It On The Run	201	1	5	180	2138	{}
2135	2019-12-22 19:02:07.347978	Tough Guys	201	2	1	180	2139	{}
2136	2019-12-22 19:02:07.347978	Out Of Season	201	2	2	180	2140	{}
2137	2019-12-22 19:02:07.347978	Shakin' It Loose	201	2	3	180	2141	{}
2138	2019-12-22 19:02:07.347978	Someone Tonight	201	2	4	180	2142	{}
2139	2019-12-22 19:02:07.347978	I Wish You Were There	201	2	5	180	2143	{}
2140	2019-12-22 19:02:07.347978	Born Under Punches (The Heat Goes On)	207	1	1	185	2144	{}
2141	2019-12-22 19:02:07.347978	Crosseyed And Painless	207	1	2	185	2145	{}
2142	2019-12-22 19:02:07.347978	The Great Curve	207	1	3	185	2146	{}
2143	2019-12-22 19:02:07.347978	Once In A Lifetime	207	2	1	185	2147	{}
2144	2019-12-22 19:02:07.347978	Houses In Motion	207	2	2	185	2148	{}
2145	2019-12-22 19:02:07.347978	Seen And Not Seen	207	2	3	185	2149	{}
2146	2019-12-22 19:02:07.347978	Listening Wind	207	2	4	185	2150	{}
2147	2019-12-22 19:02:07.347978	The Overload	207	2	5	185	2151	{}
2148	2019-12-22 19:02:07.347978	Plainsong	30	1	1	28	2152	{}
2149	2019-12-22 19:02:07.347978	Pictures Of You	30	1	2	28	2153	{}
2150	2019-12-22 19:02:07.347978	Closedown	30	1	3	28	2154	{}
2151	2019-12-22 19:02:07.347978	Lovesong	30	2	1	28	2155	{}
2152	2019-12-22 19:02:07.347978	Last Dance	30	2	2	28	2156	{}
2153	2019-12-22 19:02:07.347978	Lullaby	30	2	3	28	2157	{}
2154	2019-12-22 19:02:07.347978	Fascination Street	30	2	4	28	2158	{}
2155	2019-12-22 19:02:07.347978	Prayers For Rain	30	3	1	28	2159	{}
2156	2019-12-22 19:02:07.347978	The Same Deep Water As You	30	3	2	28	2160	{}
2157	2019-12-22 19:02:07.347978	Disintegration	30	4	1	28	2161	{}
2158	2019-12-22 19:02:07.347978	Homesick	30	4	2	28	2162	{}
2159	2019-12-22 19:02:07.347978	Untitled	30	4	3	28	2163	{}
2160	2019-12-22 19:02:07.347978	We Will Rock You	94	1	1	94	2164	{}
2161	2019-12-22 19:02:07.347978	We Are The Champions	94	1	2	94	2165	{}
2162	2019-12-22 19:02:07.347978	Sheer Heart Attack	94	1	3	94	2166	{}
2163	2019-12-22 19:02:07.347978	All Dead, All Dead	94	1	4	94	2167	{}
2164	2019-12-22 19:02:07.347978	Spread Your Wings	94	1	5	94	2168	{}
2165	2019-12-22 19:02:07.347978	Fight From The Inside	94	1	6	94	2169	{}
2166	2019-12-22 19:02:07.347978	Get Down, Make Love	94	2	1	94	2170	{}
2167	2019-12-22 19:02:07.347978	Sleeping On The Sidewalk	94	2	2	94	2171	{}
2168	2019-12-22 19:02:07.347978	Who Needs You	94	2	3	94	2172	{}
2169	2019-12-22 19:02:07.347978	It's Late	94	2	4	94	2173	{}
2170	2019-12-22 19:02:07.347978	My Melancholy Blues	94	2	5	94	2174	{}
2171	2019-12-22 19:02:07.347978	The Sounds Of Silence	225	1	1	128	2175	{}
2172	2019-12-22 19:02:07.347978	The Singleman Party Foxtrot	225	1	2	170	2176	{}
2173	2019-12-22 19:02:07.347978	Mrs. Robinson	225	1	3	128	2177	{}
2174	2019-12-22 19:02:07.347978	Sunporch Cha-Cha-Cha	225	1	4	170	2178	{}
2175	2019-12-22 19:02:07.347978	Scarborough Fair / Canticle (Interlude)	225	1	5	128	2179	{}
2176	2019-12-22 19:02:07.347978	On The Strip	225	1	6	170	2180	{}
2177	2019-12-22 19:02:07.347978	April Come She Will	225	1	7	128	2181	{}
2178	2019-12-22 19:02:07.347978	The Folks	225	1	8	170	2182	{}
2179	2019-12-22 19:02:07.347978	Scarborough Fair / Canticle	225	2	1	128	2183	{}
2180	2019-12-22 19:02:07.347978	A Great Effect	225	2	2	170	2184	{}
2181	2019-12-22 19:02:07.347978	The Big Bright Green Pleasure Machine	225	2	3	128	2185	{}
2182	2019-12-22 19:02:07.347978	Whew	225	2	4	170	2186	{}
2183	2019-12-22 19:02:07.347978	Mrs. Robinson	225	2	5	128	2187	{}
2184	2019-12-22 19:02:07.347978	The Sounds Of Silence	225	2	6	128	2188	{}
2185	2019-12-22 19:02:07.347978	Jesus Alone	2	1	1	3	2189	{}
2186	2019-12-22 19:02:07.347978	Rings Of Saturn	2	1	2	3	2190	{}
2187	2019-12-22 19:02:07.347978	Girl In Amber	2	1	3	3	2191	{}
2188	2019-12-22 19:02:07.347978	Magneto	2	1	4	3	2192	{}
2189	2019-12-22 19:02:07.347978	Anthrocene	2	2	1	3	2193	{}
2190	2019-12-22 19:02:07.347978	I Need You	2	2	2	3	2194	{}
2191	2019-12-22 19:02:07.347978	Distant Sky	2	2	3	3	2195	{}
2192	2019-12-22 19:02:07.347978	Skeleton Tree	2	2	4	3	2196	{}
2193	2019-12-22 19:02:07.347978	Let It Happen	113	1	1	111	2197	{}
2194	2019-12-22 19:02:07.347978	Nangs	113	1	2	111	2198	{}
2195	2019-12-22 19:02:07.347978	The Moment	113	1	3	111	2199	{}
2196	2019-12-22 19:02:07.347978	Yes I'm Changing	113	2	1	111	2200	{}
2197	2019-12-22 19:02:07.347978	Eventually	113	2	2	111	2201	{}
2198	2019-12-22 19:02:07.347978	Gossip	113	2	3	111	2202	{}
2199	2019-12-22 19:02:07.347978	The Less I Know The Better	113	3	1	111	2203	{}
2200	2019-12-22 19:02:07.347978	Past Life	113	3	2	111	2204	{}
2201	2019-12-22 19:02:07.347978	Disciples	113	3	3	111	2205	{}
2202	2019-12-22 19:02:07.347978	Cause I'm A Man	113	3	4	111	2206	{}
2203	2019-12-22 19:02:07.347978	Reality In Motion	113	4	1	111	2207	{}
2204	2019-12-22 19:02:07.347978	Love / Paranoia	113	4	2	111	2208	{}
2205	2019-12-22 19:02:07.347978	New Person, Same Old Mistakes	113	4	3	111	2209	{}
2206	2019-12-22 19:02:07.347978	The Boy In The Bubble	167	1	1	162	2210	{}
2207	2019-12-22 19:02:07.347978	Graceland	167	1	2	162	2211	{}
2208	2019-12-22 19:02:07.347978	I Know What I Know	167	1	3	162	2212	{}
2209	2019-12-22 19:02:07.347978	Gumboots	167	1	4	162	2213	{}
2210	2019-12-22 19:02:07.347978	Diamonds On The Soles Of Her Shoes	167	1	5	162	2214	{}
2211	2019-12-22 19:02:07.347978	You Can Call Me Al	167	2	1	162	2215	{}
2212	2019-12-22 19:02:07.347978	Under African Skies	167	2	2	162	2216	{}
2213	2019-12-22 19:02:07.347978	Homeless	167	2	3	162	2217	{}
2214	2019-12-22 19:02:07.347978	Crazy Love, Vol. II	167	2	4	162	2218	{}
2215	2019-12-22 19:02:07.347978	That Was Your Mother	167	2	5	162	2219	{}
2216	2019-12-22 19:02:07.347978	All Around The World Or The Myth Of Fingerprints	167	2	6	162	2220	{}
2217	2019-12-22 19:02:07.347978	Telegraph Road	223	1	1	197	2221	{}
2218	2019-12-22 19:02:07.347978	Private Investigations	223	1	2	197	2222	{}
2219	2019-12-22 19:02:07.347978	Industrial Disease	223	2	1	197	2223	{}
2220	2019-12-22 19:02:07.347978	Love Over Gold	223	2	2	197	2224	{}
2221	2019-12-22 19:02:07.347978	It Never Rains	223	2	3	197	2225	{}
2222	2019-12-22 19:02:07.347978	25 Or 6 To 4	124	1	1	125	2226	{}
2223	2019-12-22 19:02:07.347978	Does Anybody Really Know What Time It Is?	124	1	2	125	2227	{}
2224	2019-12-22 19:02:07.347978	Colour My World	124	1	3	125	2228	{}
2225	2019-12-22 19:02:07.347978	Just You 'N' Me	124	1	4	125	2229	{}
2226	2019-12-22 19:02:07.347978	Saturday In The Park	124	1	5	125	2230	{}
2227	2019-12-22 19:02:07.347978	Feelin' Stronger Every Day	124	1	6	125	2231	{}
2228	2019-12-22 19:02:07.347978	Make Me Smile	124	2	1	125	2232	{}
2229	2019-12-22 19:02:07.347978	Wishing You Were Here	124	2	2	125	2233	{}
2230	2019-12-22 19:02:07.347978	Call On Me	124	2	3	125	2234	{}
2231	2019-12-22 19:02:07.347978	(I've Been) Searchin' So Long	124	2	4	125	2235	{}
2232	2019-12-22 19:02:07.347978	Beginnings	124	2	5	125	2236	{}
2233	2019-12-22 19:02:07.347978	Bloom	18	1	1	17	2237	{}
2234	2019-12-22 19:02:07.347978	Morning Mr Magpie	18	1	2	17	2238	{}
2235	2019-12-22 19:02:07.347978	Little By Little	18	2	1	17	2239	{}
2236	2019-12-22 19:02:07.347978	Feral	18	2	2	17	2240	{}
2237	2019-12-22 19:02:07.347978	Lotus Flower	18	3	1	17	2241	{}
2238	2019-12-22 19:02:07.347978	Codex	18	3	2	17	2242	{}
2239	2019-12-22 19:02:07.347978	Give Up The Ghost	18	4	1	17	2243	{}
2240	2019-12-22 19:02:07.347978	Separator	18	4	2	17	2244	{}
2241	2019-12-22 19:02:07.347978	Bloom	18	5	1	17	2245	{}
2242	2019-12-22 19:02:07.347978	Morning Mr Magpie	18	5	2	17	2246	{}
2243	2019-12-22 19:02:07.347978	Little By Little	18	5	3	17	2247	{}
2244	2019-12-22 19:02:07.347978	Feral	18	5	4	17	2248	{}
2245	2019-12-22 19:02:07.347978	Lotus Flower	18	5	5	17	2249	{}
2246	2019-12-22 19:02:07.347978	Codex	18	5	6	17	2250	{}
2247	2019-12-22 19:02:07.347978	Give Up The Ghost	18	5	7	17	2251	{}
2248	2019-12-22 19:02:07.347978	Separator	18	5	8	17	2252	{}
2249	2019-12-22 19:02:07.347978	I'd Have You Anytime	27	1	1	25	2253	{}
2250	2019-12-22 19:02:07.347978	My Sweet Lord	27	1	2	25	2254	{}
2251	2019-12-22 19:02:07.347978	Wah-Wah	27	1	3	25	2255	{}
2252	2019-12-22 19:02:07.347978	Isn't It A Pity (Version One)	27	1	4	25	2256	{}
2253	2019-12-22 19:02:07.347978	What Is Life	27	2	1	25	2257	{}
2254	2019-12-22 19:02:07.347978	If Not For You	27	2	2	25	2258	{}
2255	2019-12-22 19:02:07.347978	Behind That Locked Door	27	2	3	25	2259	{}
2256	2019-12-22 19:02:07.347978	Let It Down	27	2	4	25	2260	{}
2257	2019-12-22 19:02:07.347978	Run Of The Mill	27	2	5	25	2261	{}
2258	2019-12-22 19:02:07.347978	Beware Of Darkness	27	3	1	25	2262	{}
2259	2019-12-22 19:02:07.347978	Apple Scruffs	27	3	2	25	2263	{}
2260	2019-12-22 19:02:07.347978	Ballad Of Sir Frankie Crisp (Let It Roll)	27	3	3	25	2264	{}
2261	2019-12-22 19:02:07.347978	Awaiting On You All	27	3	4	25	2265	{}
2262	2019-12-22 19:02:07.347978	All Things Must Pass	27	3	5	25	2266	{}
2263	2019-12-22 19:02:07.347978	I Dig Love	27	4	1	25	2267	{}
2264	2019-12-22 19:02:07.347978	Art Of Dying	27	4	2	25	2268	{}
2265	2019-12-22 19:02:07.347978	Isn't It A Pity (Version Two)	27	4	3	25	2269	{}
2266	2019-12-22 19:02:07.347978	Hear Me Lord	27	4	4	25	2270	{}
2267	2019-12-22 19:02:07.347978	Apple Jam	27	4	5	25	2271	{}
2268	2019-12-22 19:02:07.347978	Out Of The Blue	27	5	1	25	2272	{}
2269	2019-12-22 19:02:07.347978	It's Johnny's Birthday	27	5	2	25	2273	{}
2270	2019-12-22 19:02:07.347978	Plug Me In	27	5	3	25	2274	{}
2271	2019-12-22 19:02:07.347978	I Remember Jeep	27	6	1	25	2275	{}
2272	2019-12-22 19:02:07.347978	Thanks For The Pepperoni	27	6	2	25	2276	{}
2273	2019-12-22 19:02:07.347978	Back In The Saddle	84	1	1	87	2277	{}
2274	2019-12-22 19:02:07.347978	Last Child	84	1	2	87	2278	{}
2275	2019-12-22 19:02:07.347978	Rats In The Cellar	84	1	3	87	2279	{}
2276	2019-12-22 19:02:07.347978	Combination	84	1	4	87	2280	{}
2277	2019-12-22 19:02:07.347978	Sick As A Dog	84	2	1	87	2281	{}
2278	2019-12-22 19:02:07.347978	Nobody's Fault	84	2	2	87	2282	{}
2279	2019-12-22 19:02:07.347978	Get The Lead Out	84	2	3	87	2283	{}
2280	2019-12-22 19:02:07.347978	Lick And A Promise	84	2	4	87	2284	{}
2281	2019-12-22 19:02:07.347978	Home Tonight	84	2	5	87	2285	{}
2282	2019-12-22 19:02:07.347978	Surfin' Safari	219	1	1	192	2286	{}
2283	2019-12-22 19:02:07.347978	Surfer Girl	219	1	2	192	2287	{}
2284	2019-12-22 19:02:07.347978	Catch A Wave	219	1	3	192	2288	{}
2285	2019-12-22 19:02:07.347978	The Warmth Of The Sun	219	1	4	192	2289	{}
2286	2019-12-22 19:02:07.347978	Surfin' U.S.A.	219	1	5	192	2290	{}
2287	2019-12-22 19:02:07.347978	Be True To Your School	219	2	1	192	2291	{}
2288	2019-12-22 19:02:07.347978	Little Deuce Coupe	219	2	2	192	2292	{}
2289	2019-12-22 19:02:07.347978	In My Room	219	2	3	192	2293	{}
2290	2019-12-22 19:02:07.347978	Shut Down	219	2	4	192	2294	{}
2291	2019-12-22 19:02:07.347978	Fun, Fun, Fun	219	2	5	192	2295	{}
2292	2019-12-22 19:02:07.347978	I Get Around	219	3	1	192	2296	{}
2293	2019-12-22 19:02:07.347978	The Girls On The Beach	219	3	2	192	2297	{}
2294	2019-12-22 19:02:07.347978	Wendy	219	3	3	192	2298	{}
2295	2019-12-22 19:02:07.347978	Let Him Run Wild	219	3	4	192	2299	{}
2296	2019-12-22 19:02:07.347978	Don't Worry Baby	219	3	5	192	2300	{}
2297	2019-12-22 19:02:07.347978	California Girls	219	4	1	192	2301	{}
2298	2019-12-22 19:02:07.347978	Girl Don't Tell Me	219	4	2	192	2302	{}
2299	2019-12-22 19:02:07.347978	Help Me, Rhonda	219	4	3	192	2303	{}
2300	2019-12-22 19:02:07.347978	You're So Good To Me	219	4	4	192	2304	{}
2301	2019-12-22 19:02:07.347978	All Summer Long	219	4	5	192	2305	{}
2302	2019-12-22 19:02:07.347978	Uh-Oh, Love Comes To Town	206	1	1	185	2306	{}
2303	2019-12-22 19:02:07.347978	New Feeling	206	1	2	185	2307	{}
2304	2019-12-22 19:02:07.347978	Tentative Decisions	206	1	3	185	2308	{}
2305	2019-12-22 19:02:07.347978	Happy Day	206	1	4	185	2309	{}
2306	2019-12-22 19:02:07.347978	Who Is It ?	206	1	5	185	2310	{}
2307	2019-12-22 19:02:07.347978	No Compassion	206	1	6	185	2311	{}
2308	2019-12-22 19:02:07.347978	The Book I Read	206	2	1	185	2312	{}
2309	2019-12-22 19:02:07.347978	Don't Worry About The Government	206	2	2	185	2313	{}
2310	2019-12-22 19:02:07.347978	First Week / Last Week...Carefree	206	2	3	185	2314	{}
2311	2019-12-22 19:02:07.347978	Psycho Killer	206	2	4	185	2315	{}
2312	2019-12-22 19:02:07.347978	Pulled Up	206	2	5	185	2316	{}
2313	2019-12-22 19:02:07.347978	I Am Trying To Break Your Heart	136	1	1	131	2317	{}
2314	2019-12-22 19:02:07.347978	Kamera	136	1	2	131	2318	{}
2315	2019-12-22 19:02:07.347978	Radio Cure	136	1	3	131	2319	{}
2316	2019-12-22 19:02:07.347978	War On War	136	2	1	131	2320	{}
2317	2019-12-22 19:02:07.347978	Jesus, Etc.	136	2	2	131	2321	{}
2318	2019-12-22 19:02:07.347978	Ashes Of American Flags	136	2	3	131	2322	{}
2319	2019-12-22 19:02:07.347978	Heavy Metal Drummer	136	3	1	131	2323	{}
2320	2019-12-22 19:02:07.347978	I'm The Man Who Loves You	136	3	2	131	2324	{}
2321	2019-12-22 19:02:07.347978	Pot Kettle Black	136	3	3	131	2325	{}
2322	2019-12-22 19:02:07.347978	Poor Places	136	4	1	131	2326	{}
2323	2019-12-22 19:02:07.347978	Reservations	136	4	2	131	2327	{}
2324	2019-12-22 19:02:07.347978	I Am Trying To Break Your Heart	136	5	1	131	2328	{}
2325	2019-12-22 19:02:07.347978	Kamera	136	5	2	131	2329	{}
2326	2019-12-22 19:02:07.347978	Radio Cure	136	5	3	131	2330	{}
2327	2019-12-22 19:02:07.347978	War On War	136	5	4	131	2331	{}
2328	2019-12-22 19:02:07.347978	Jesus, Etc.	136	5	5	131	2332	{}
2329	2019-12-22 19:02:07.347978	Ashes Of American Flags	136	5	6	131	2333	{}
2330	2019-12-22 19:02:07.347978	Heavy Metal Drummer	136	5	7	131	2334	{}
2331	2019-12-22 19:02:07.347978	I'm The Man Who Loves You	136	5	8	131	2335	{}
2332	2019-12-22 19:02:07.347978	Pot Kettle Black	136	5	9	131	2336	{}
2333	2019-12-22 19:02:07.347978	Poor Places	136	5	10	131	2337	{}
2334	2019-12-22 19:02:07.347978	Reservations	136	5	11	131	2338	{}
2335	2019-12-22 19:02:07.347978	Chameleon	115	1	1	112	2339	{}
2336	2019-12-22 19:02:07.347978	Watermelon Man	115	1	2	112	2340	{}
2337	2019-12-22 19:02:07.347978	Sly	115	2	1	112	2341	{}
2338	2019-12-22 19:02:07.347978	Vein Melter	115	2	2	112	2342	{}
2339	2019-12-22 19:02:07.347978	Runnin' With The Devil	141	1	1	138	2343	{}
2340	2019-12-22 19:02:07.347978	Eruption	141	1	2	138	2344	{}
2341	2019-12-22 19:02:07.347978	You Really Got Me	141	1	3	138	2345	{}
2342	2019-12-22 19:02:07.347978	Ain't Talkin' 'Bout Love	141	1	4	138	2346	{}
2343	2019-12-22 19:02:07.347978	I'm The One	141	1	5	138	2347	{}
2344	2019-12-22 19:02:07.347978	Jamie's Cryin'	141	2	1	138	2348	{}
2345	2019-12-22 19:02:07.347978	Atomic Punk	141	2	2	138	2349	{}
2346	2019-12-22 19:02:07.347978	Feel Your Love Tonight	141	2	3	138	2350	{}
2347	2019-12-22 19:02:07.347978	Little Dreamer	141	2	4	138	2351	{}
2348	2019-12-22 19:02:07.347978	Ice Cream Man	141	2	5	138	2352	{}
2349	2019-12-22 19:02:07.347978	On Fire	141	2	6	138	2353	{}
2350	2019-12-22 19:02:07.347978	Wake Me Up Before You Go-Go	3	1	1	4	2354	{}
2351	2019-12-22 19:02:07.347978	Everything She Wants	3	1	2	4	2355	{}
2352	2019-12-22 19:02:07.347978	Heartbeat	3	1	3	4	2356	{}
2353	2019-12-22 19:02:07.347978	Like A Baby	3	1	4	4	2357	{}
2354	2019-12-22 19:02:07.347978	Freedom	3	2	1	4	2358	{}
2355	2019-12-22 19:02:07.347978	If You Were There	3	2	2	4	2359	{}
2356	2019-12-22 19:02:07.347978	Credit Card Baby	3	2	3	4	2360	{}
2357	2019-12-22 19:02:07.347978	Careless Whisper	3	2	4	4	2361	{}
2358	2019-12-22 19:02:07.347978	Tautou	220	1	1	193	2362	{}
2359	2019-12-22 19:02:07.347978	Sic Transit Gloria ... Glory Fades	220	1	2	193	2363	{}
2360	2019-12-22 19:02:07.347978	I Will Play My Game Beneath The Spin Light	220	1	3	193	2364	{}
2361	2019-12-22 19:02:07.347978	Okay I Believe You, But My Tommy Gun Don't	220	2	1	193	2365	{}
2362	2019-12-22 19:02:07.347978	The Quiet Things That No One Ever Knows	220	2	2	193	2366	{}
2363	2019-12-22 19:02:07.347978	The Boy Who Blocked His Own Shot	220	2	3	193	2367	{}
2364	2019-12-22 19:02:07.347978	Jaws Theme Swimming	220	3	1	193	2368	{}
2365	2019-12-22 19:02:07.347978	Me Vs. Maradona Vs. Elvis	220	3	2	193	2369	{}
2366	2019-12-22 19:02:07.347978	Guernica	220	3	3	193	2370	{}
2367	2019-12-22 19:02:07.347978	Good To Know That If I Ever Need Attention All I Need To Do Is Die	220	4	1	193	2371	{}
2368	2019-12-22 19:02:07.347978	Play Crack The Sky	220	4	2	193	2372	{}
2369	2019-12-22 19:02:07.347978	Coming Home	157	1	1	150	2373	{}
2370	2019-12-22 19:02:07.347978	Better Man	157	1	2	150	2374	{}
2371	2019-12-22 19:02:07.347978	Brown Skin Girl	157	1	3	150	2375	{}
2372	2019-12-22 19:02:07.347978	Smooth Sailin'	157	1	4	150	2376	{}
2373	2019-12-22 19:02:07.347978	Shine	157	1	5	150	2377	{}
2374	2019-12-22 19:02:07.347978	Lisa Sawyer	157	2	1	150	2378	{}
2375	2019-12-22 19:02:07.347978	Flowers	157	2	2	150	2379	{}
2376	2019-12-22 19:02:07.347978	Pull Away	157	2	3	150	2380	{}
2377	2019-12-22 19:02:07.347978	Twistin' & Groovin'	157	2	4	150	2381	{}
2378	2019-12-22 19:02:07.347978	River	157	2	5	150	2382	{}
2379	2019-12-22 19:02:07.347978	Love Me Do	178	1	1	171	2383	{}
2380	2019-12-22 19:02:07.347978	Please Please Me	178	1	2	171	2384	{}
2381	2019-12-22 19:02:07.347978	From Me To You	178	1	3	171	2385	{}
2382	2019-12-22 19:02:07.347978	She Loves You	178	1	4	171	2386	{}
2383	2019-12-22 19:02:07.347978	I Want To Hold Your Hand	178	1	5	171	2387	{}
2384	2019-12-22 19:02:07.347978	All My Loving	178	1	6	171	2388	{}
2385	2019-12-22 19:02:07.347978	Can't Buy Me Love	178	1	7	171	2389	{}
2386	2019-12-22 19:02:07.347978	A Hard Day's Night	178	2	1	171	2390	{}
2387	2019-12-22 19:02:07.347978	And I Love Her	178	2	2	171	2391	{}
2388	2019-12-22 19:02:07.347978	Eight Days A Week	178	2	3	171	2392	{}
2389	2019-12-22 19:02:07.347978	I Feel Fine	178	2	4	171	2393	{}
2390	2019-12-22 19:02:07.347978	Ticket To Ride	178	2	5	171	2394	{}
2391	2019-12-22 19:02:07.347978	Yesterday	178	2	6	171	2395	{}
2392	2019-12-22 19:02:07.347978	Help!	178	3	1	171	2396	{}
2393	2019-12-22 19:02:07.347978	You've Got To Hide Your Love Away	178	3	2	171	2397	{}
2394	2019-12-22 19:02:07.347978	We Can Work It Out	178	3	3	171	2398	{}
2395	2019-12-22 19:02:07.347978	Day Tripper	178	3	4	171	2399	{}
2396	2019-12-22 19:02:07.347978	Drive My Car	178	3	5	171	2400	{}
2397	2019-12-22 19:02:07.347978	Norwegian Wood (This Bird Has Flown)	178	3	6	171	2401	{}
2398	2019-12-22 19:02:07.347978	Nowhere Man	178	4	1	171	2402	{}
2399	2019-12-22 19:02:07.347978	Michelle	178	4	2	171	2403	{}
2400	2019-12-22 19:02:07.347978	In My Life	178	4	3	171	2404	{}
2401	2019-12-22 19:02:07.347978	Girl	178	4	4	171	2405	{}
2402	2019-12-22 19:02:07.347978	Paperback Writer	178	4	5	171	2406	{}
2403	2019-12-22 19:02:07.347978	Eleanor Rigby	178	4	6	171	2407	{}
2404	2019-12-22 19:02:07.347978	Yellow Submarine	178	4	7	171	2408	{}
2405	2019-12-22 19:02:07.347978	Setting Forth	121	1	1	121	2409	{}
2406	2019-12-22 19:02:07.347978	No Ceiling	121	1	2	121	2410	{}
2407	2019-12-22 19:02:07.347978	Far Behind	121	1	3	121	2411	{}
2408	2019-12-22 19:02:07.347978	Rise	121	1	4	121	2412	{}
2409	2019-12-22 19:02:07.347978	Tuolumne	121	1	5	121	2413	{}
2410	2019-12-22 19:02:07.347978	Long Nights	121	1	6	121	2414	{}
2411	2019-12-22 19:02:07.347978	Guaranteed (Humming Version)	121	1	7	121	2415	{}
2412	2019-12-22 19:02:07.347978	Hard Sun	121	2	1	121	2416	{}
2413	2019-12-22 19:02:07.347978	Society	121	2	2	121	2417	{}
2414	2019-12-22 19:02:07.347978	The Wolf	121	2	3	121	2418	{}
2415	2019-12-22 19:02:07.347978	End Of The Road	121	2	4	121	2419	{}
2416	2019-12-22 19:02:07.347978	Guaranteed	121	2	5	121	2420	{}
2417	2019-12-22 19:02:07.347978	G	50	1	2	49	2421	{}
2418	2019-12-22 19:02:07.347978	Welcome To The Jungle	50	2	1	49	2422	{}
2419	2019-12-22 19:02:07.347978	It's So Easy	50	2	2	49	2423	{}
2420	2019-12-22 19:02:07.347978	Nightrain	50	2	3	49	2424	{}
2421	2019-12-22 19:02:07.347978	Out Ta Get Me	50	2	4	49	2425	{}
2422	2019-12-22 19:02:07.347978	Mr. Brownstone	50	2	5	49	2426	{}
2423	2019-12-22 19:02:07.347978	Paradise City	50	2	6	49	2427	{}
2424	2019-12-22 19:02:07.347978	R	50	2	7	49	2428	{}
2425	2019-12-22 19:02:07.347978	My Michelle	50	3	1	49	2429	{}
2426	2019-12-22 19:02:07.347978	Think About You	50	3	2	49	2430	{}
2427	2019-12-22 19:02:07.347978	Sweet Child O' Mine	50	3	3	49	2431	{}
2428	2019-12-22 19:02:07.347978	You're Crazy	50	3	4	49	2432	{}
2429	2019-12-22 19:02:07.347978	Anything Goes	50	3	5	49	2433	{}
2430	2019-12-22 19:02:07.347978	Rocket Queen	50	3	6	49	2434	{}
2431	2019-12-22 19:02:07.347978	Take It Easy	148	1	1	142	2435	{}
2432	2019-12-22 19:02:07.347978	Witchy Woman	148	1	2	142	2436	{}
2433	2019-12-22 19:02:07.347978	Lyin' Eyes	148	1	3	142	2437	{}
2434	2019-12-22 19:02:07.347978	Already Gone	148	1	4	142	2438	{}
2435	2019-12-22 19:02:07.347978	Desperado	148	1	5	142	2439	{}
2436	2019-12-22 19:02:07.347978	One Of These Nights	148	2	1	142	2440	{}
2437	2019-12-22 19:02:07.347978	Tequila Sunrise	148	2	2	142	2441	{}
2438	2019-12-22 19:02:07.347978	Take It To The Limit	148	2	3	142	2442	{}
2439	2019-12-22 19:02:07.347978	Peaceful, Easy Feeling	148	2	4	142	2443	{}
2440	2019-12-22 19:02:07.347978	Best Of My Love	148	2	5	142	2444	{}
2441	2019-12-22 19:02:07.347978	Big Love	34	1	1	34	2445	{}
2442	2019-12-22 19:02:07.347978	Seven Wonders	34	1	2	34	2446	{}
2443	2019-12-22 19:02:07.347978	Everywhere	34	1	3	34	2447	{}
2444	2019-12-22 19:02:07.347978	Caroline	34	1	4	34	2448	{}
2445	2019-12-22 19:02:07.347978	Tango In The Night	34	1	5	34	2449	{}
2446	2019-12-22 19:02:07.347978	Mystified	34	1	6	34	2450	{}
2447	2019-12-22 19:02:07.347978	Little Lies	34	2	1	34	2451	{}
2448	2019-12-22 19:02:07.347978	Family Man	34	2	2	34	2452	{}
2449	2019-12-22 19:02:07.347978	Welcome To The Room...Sara	34	2	3	34	2453	{}
2450	2019-12-22 19:02:07.347978	Isn't It Midnight	34	2	4	34	2454	{}
2451	2019-12-22 19:02:07.347978	When I See You Again	34	2	5	34	2455	{}
2452	2019-12-22 19:02:07.347978	You And I, Part II	34	2	6	34	2456	{}
2453	2019-12-22 19:02:07.347978	Let Me Out	28	1	1	26	2457	{}
2454	2019-12-22 19:02:07.347978	Your Number Or Your Name	28	1	2	26	2458	{}
2455	2019-12-22 19:02:07.347978	Oh Tara	28	1	3	26	2459	{}
2456	2019-12-22 19:02:07.347978	(She's So) Selfish	28	1	4	26	2460	{}
2457	2019-12-22 19:02:07.347978	Maybe Tonight	28	1	5	26	2461	{}
2458	2019-12-22 19:02:07.347978	Good Girls Don't	28	1	6	26	2462	{}
2459	2019-12-22 19:02:07.347978	My Sharona	28	2	1	26	2463	{}
2460	2019-12-22 19:02:07.347978	Heartbeat	28	2	2	26	2464	{}
2461	2019-12-22 19:02:07.347978	Siamese Twins (The Monkey And Me)	28	2	3	26	2465	{}
2462	2019-12-22 19:02:07.347978	Lucinda	28	2	4	26	2466	{}
2463	2019-12-22 19:02:07.347978	That's What The Little Girls Do	28	2	5	26	2467	{}
2464	2019-12-22 19:02:07.347978	Frustrated	28	2	6	26	2468	{}
2465	2019-12-22 19:02:07.347978	Badlands	193	1	1	177	2469	{}
2466	2019-12-22 19:02:07.347978	Adam Raised A Cain	193	1	2	177	2470	{}
2467	2019-12-22 19:02:07.347978	Something In The Night	193	1	3	177	2471	{}
2468	2019-12-22 19:02:07.347978	Candy's Room	193	1	4	177	2472	{}
2469	2019-12-22 19:02:07.347978	Racing In The Street	193	1	5	177	2473	{}
2470	2019-12-22 19:02:07.347978	The Promised Land	193	2	1	177	2474	{}
2471	2019-12-22 19:02:07.347978	Factory	193	2	2	177	2475	{}
2472	2019-12-22 19:02:07.347978	Streets Of Fire	193	2	3	177	2476	{}
2473	2019-12-22 19:02:07.347978	Prove It All Night	193	2	4	177	2477	{}
2474	2019-12-22 19:02:07.347978	Darkness On The Edge Of Town	193	2	5	177	2478	{}
2475	2019-12-22 19:02:07.347978	Down To The Waterline	222	1	1	197	2479	{}
2476	2019-12-22 19:02:07.347978	Water Of Love	222	1	2	197	2480	{}
2477	2019-12-22 19:02:07.347978	Setting Me Up	222	1	3	197	2481	{}
2478	2019-12-22 19:02:07.347978	Six Blade Knife	222	1	4	197	2482	{}
2479	2019-12-22 19:02:07.347978	Southbound Again	222	1	5	197	2483	{}
2480	2019-12-22 19:02:07.347978	Sultans Of Swing	222	2	1	197	2484	{}
2481	2019-12-22 19:02:07.347978	In The Gallery	222	2	2	197	2485	{}
2482	2019-12-22 19:02:07.347978	Wild West End	222	2	3	197	2486	{}
2483	2019-12-22 19:02:07.347978	Lions	222	2	4	197	2487	{}
2484	2019-12-22 19:02:07.347978	Seven Nation Army	137	1	1	132	2488	{}
2485	2019-12-22 19:02:07.347978	Black Math	137	1	2	132	2489	{}
2486	2019-12-22 19:02:07.347978	There's No Home For You Here 	137	1	3	132	2490	{}
2487	2019-12-22 19:02:07.347978	I Just Don't Know What To Do With Myself 	137	2	1	132	2491	{}
2488	2019-12-22 19:02:07.347978	In The Cold, Cold Night 	137	2	2	132	2492	{}
2489	2019-12-22 19:02:07.347978	I Want To Be The Boy To Warm Your Mother's Heart 	137	2	3	132	2493	{}
2490	2019-12-22 19:02:07.347978	You've Got Her In Your Pocket 	137	2	4	132	2494	{}
2491	2019-12-22 19:02:07.347978	Ball And Biscuit 	137	3	1	132	2495	{}
2492	2019-12-22 19:02:07.347978	The Hardest Button To Button 	137	3	2	132	2496	{}
2493	2019-12-22 19:02:07.347978	Little Acorns 	137	3	3	132	2497	{}
2494	2019-12-22 19:02:07.347978	Hypnotize	137	4	1	132	2498	{}
2495	2019-12-22 19:02:07.347978	The Air Near My Fingers	137	4	2	132	2499	{}
2496	2019-12-22 19:02:07.347978	Girl, You Have No Faith In Medicine 	137	4	3	132	2500	{}
2497	2019-12-22 19:02:07.347978	It's True That We Love One Another 	137	4	4	132	2501	{}
2498	2019-12-22 19:02:07.347978	Intro	92	1	1	93	2502	{}
2499	2019-12-22 19:02:07.347978	Last Living Souls	92	1	2	93	2503	{}
2500	2019-12-22 19:02:07.347978	Kids With Guns	92	1	3	93	2504	{}
2501	2019-12-22 19:02:07.347978	O Green World	92	1	4	93	2505	{}
2502	2019-12-22 19:02:07.347978	Dirty Harry	92	2	1	93	2506	{}
2503	2019-12-22 19:02:07.347978	Feel Good Inc.	92	2	2	93	2507	{}
2504	2019-12-22 19:02:07.347978	El Mañana	92	2	3	93	2508	{}
2505	2019-12-22 19:02:07.347978	Every Planet We Reach Is Dead	92	3	1	93	2509	{}
2506	2019-12-22 19:02:07.347978	November Has Come	92	3	2	93	2510	{}
2507	2019-12-22 19:02:07.347978	All Alone	92	3	3	93	2511	{}
2508	2019-12-22 19:02:07.347978	White Light	92	3	4	93	2512	{}
2509	2019-12-22 19:02:07.347978	Dare	92	4	1	93	2513	{}
2510	2019-12-22 19:02:07.347978	Fire Coming Out Of The Monkey's Head	92	4	2	93	2514	{}
2511	2019-12-22 19:02:07.347978	Don't Get Lost In Heaven	92	4	3	93	2515	{}
2512	2019-12-22 19:02:07.347978	Demon Days	92	4	4	93	2516	{}
2513	2019-12-22 19:02:07.347978	Hello, I Love You	65	1	1	65	2517	{}
2514	2019-12-22 19:02:07.347978	Love Street	65	1	2	65	2518	{}
2515	2019-12-22 19:02:07.347978	Not To Touch The Earth	65	1	3	65	2519	{}
2516	2019-12-22 19:02:07.347978	Summer's Almost Gone	65	1	4	65	2520	{}
2517	2019-12-22 19:02:07.347978	Wintertime Love	65	1	5	65	2521	{}
2518	2019-12-22 19:02:07.347978	The Unknown Soldier	65	1	6	65	2522	{}
2519	2019-12-22 19:02:07.347978	Spanish Caravan	65	2	1	65	2523	{}
2520	2019-12-22 19:02:07.347978	My Wild Love	65	2	2	65	2524	{}
2521	2019-12-22 19:02:07.347978	We Could Be So Good Together	65	2	3	65	2525	{}
2522	2019-12-22 19:02:07.347978	Yes, The River Knows	65	2	4	65	2526	{}
2523	2019-12-22 19:02:07.347978	Five To One	65	2	5	65	2527	{}
2524	2019-12-22 19:02:07.347978	In The Flowers	43	1	1	38	2528	{}
2525	2019-12-22 19:02:07.347978	My Girls	43	1	2	38	2529	{}
2526	2019-12-22 19:02:07.347978	Also Frightened	43	1	3	38	2530	{}
2527	2019-12-22 19:02:07.347978	Summertime Clothes	43	2	1	38	2531	{}
2528	2019-12-22 19:02:07.347978	Daily Routine	43	2	2	38	2532	{}
2529	2019-12-22 19:02:07.347978	Bluish	43	2	3	38	2533	{}
2530	2019-12-22 19:02:07.347978	Guys Eyes	43	3	1	38	2534	{}
2531	2019-12-22 19:02:07.347978	Taste	43	3	2	38	2535	{}
2532	2019-12-22 19:02:07.347978	Lion In A Coma	43	3	3	38	2536	{}
2533	2019-12-22 19:02:07.347978	No More Runnin	43	4	1	38	2537	{}
2534	2019-12-22 19:02:07.347978	Brother Sport	43	4	2	38	2538	{}
2535	2019-12-22 19:02:07.347978	Rock 'n' Roll Star	217	1	1	191	2539	{}
2536	2019-12-22 19:02:07.347978	Shakermaker	217	1	2	191	2540	{}
2537	2019-12-22 19:02:07.347978	Live Forever	217	1	3	191	2541	{}
2538	2019-12-22 19:02:07.347978	Up In The Sky	217	2	1	191	2542	{}
2539	2019-12-22 19:02:07.347978	Columbia	217	2	2	191	2543	{}
2540	2019-12-22 19:02:07.347978	Sad Song	217	2	3	191	2544	{}
2541	2019-12-22 19:02:07.347978	Supersonic	217	3	1	191	2545	{}
2542	2019-12-22 19:02:07.347978	Bring It On Down	217	3	2	191	2546	{}
2543	2019-12-22 19:02:07.347978	Cigarettes & Alcohol	217	3	3	191	2547	{}
2544	2019-12-22 19:02:07.347978	Digsy's Dinner	217	4	1	191	2548	{}
2545	2019-12-22 19:02:07.347978	Slide Away	217	4	2	191	2549	{}
2546	2019-12-22 19:02:07.347978	Married With Children	217	4	3	191	2550	{}
2547	2019-12-22 19:02:07.347978	Bathtub	4	1	1	5	2551	{}
2548	2019-12-22 19:02:07.347978	G Funk Intro	4	1	2	5	2552	{}
2549	2019-12-22 19:02:07.347978	Gin And Juice	4	1	3	5	2553	{}
2550	2019-12-22 19:02:07.347978	Tha Shiznit	4	1	4	5	2554	{}
2551	2019-12-22 19:02:07.347978	Lodi Dodi	4	2	1	5	2555	{}
2552	2019-12-22 19:02:07.347978	Murder Was The Case (Death After Visualizing Eternity)	4	2	2	5	2556	{}
2553	2019-12-22 19:02:07.347978	Serial Killa	4	2	3	5	2557	{}
2554	2019-12-22 19:02:07.347978	Who Am I (What's My Name)?	4	3	1	5	2558	{}
2555	2019-12-22 19:02:07.347978	For All My Niggaz & Bitches	4	3	2	176	2559	{}
2556	2019-12-22 19:02:07.347978	Aint No Fun (If The Homies Cant Have None)	4	3	3	5	2560	{}
2557	2019-12-22 19:02:07.347978	Doggy Dogg World	4	4	1	5	2561	{}
2558	2019-12-22 19:02:07.347978	Gz And Hustlas	4	4	2	5	2562	{}
2559	2019-12-22 19:02:07.347978	Pump Pump	4	4	3	5	2563	{}
2560	2019-12-22 19:02:07.347978	EXP	190	1	1	175	2564	{}
2561	2019-12-22 19:02:07.347978	Up From The Skies	190	1	2	175	2565	{}
2562	2019-12-22 19:02:07.347978	Spanish Castle Magic	190	1	3	175	2566	{}
2563	2019-12-22 19:02:07.347978	Wait Until Tomorrow	190	1	4	175	2567	{}
2564	2019-12-22 19:02:07.347978	Ain't No Telling	190	1	5	175	2568	{}
2565	2019-12-22 19:02:07.347978	Little Wing	190	1	6	175	2569	{}
2566	2019-12-22 19:02:07.347978	If 6 Was 9	190	1	7	175	2570	{}
2567	2019-12-22 19:02:07.347978	You Got Me Floating	190	2	1	175	2571	{}
2568	2019-12-22 19:02:07.347978	Castles Made Of Sand	190	2	2	175	2572	{}
2569	2019-12-22 19:02:07.347978	She's So Fine	190	2	3	175	2573	{}
2570	2019-12-22 19:02:07.347978	One Rainy Wish	190	2	4	175	2574	{}
2571	2019-12-22 19:02:07.347978	Little Miss Lover	190	2	5	175	2575	{}
2572	2019-12-22 19:02:07.347978	Bold As Love	190	2	6	175	2576	{}
2573	2019-12-22 19:02:07.347978	Red Rain	44	1	1	39	2577	{}
2574	2019-12-22 19:02:07.347978	Sledgehammer	44	1	2	39	2578	{}
2575	2019-12-22 19:02:07.347978	Don't Give Up	44	1	3	39	2579	{}
2576	2019-12-22 19:02:07.347978	That Voice Again	44	1	4	39	2580	{}
2577	2019-12-22 19:02:07.347978	In Your Eyes	44	2	1	39	2581	{}
2578	2019-12-22 19:02:07.347978	Mercy Street (For Anne Sexton)	44	2	2	39	2582	{}
2579	2019-12-22 19:02:07.347978	Big Time (Suc Cess)	44	2	3	39	2583	{}
2580	2019-12-22 19:02:07.347978	We Do What We're Told (Milgram's 37)	44	2	4	39	2584	{}
2581	2019-12-22 19:02:07.347978	Miss You	162	1	1	158	2585	{}
2582	2019-12-22 19:02:07.347978	When The  Whip Comes Down	162	1	2	158	2586	{}
2583	2019-12-22 19:02:07.347978	Just My Imagination (Running Away With Me)	162	1	3	158	2587	{}
2584	2019-12-22 19:02:07.347978	Some Girls	162	1	4	158	2588	{}
2585	2019-12-22 19:02:07.347978	Lies	162	1	5	158	2589	{}
2586	2019-12-22 19:02:07.347978	Far Away Eyes	162	2	1	158	2590	{}
2587	2019-12-22 19:02:07.347978	Respectable	162	2	2	158	2591	{}
2588	2019-12-22 19:02:07.347978	Before They Make Me Run	162	2	3	158	2592	{}
2589	2019-12-22 19:02:07.347978	Beast Of Burden	162	2	4	158	2593	{}
2590	2019-12-22 19:02:07.347978	Shattered	162	2	5	158	2594	{}
2591	2019-12-22 19:02:07.347978	I Robot	116	1	1	113	2595	{}
2592	2019-12-22 19:02:07.347978	I Wouldn't Want To Be Like You	116	1	2	113	2596	{}
2593	2019-12-22 19:02:07.347978	Some Other Time	116	1	3	113	2597	{}
2594	2019-12-22 19:02:07.347978	Breakdown	116	1	4	113	2598	{}
2595	2019-12-22 19:02:07.347978	Don't Let It Show	116	1	5	113	2599	{}
2596	2019-12-22 19:02:07.347978	The Voice	116	2	1	113	2600	{}
2597	2019-12-22 19:02:07.347978	Nucleus	116	2	2	113	2601	{}
2598	2019-12-22 19:02:07.347978	Day After Day (The Show Must Go On)	116	2	3	113	2602	{}
2599	2019-12-22 19:02:07.347978	Total Eclipse	116	2	4	113	2603	{}
2600	2019-12-22 19:02:07.347978	Genesis Ch.1, V.32	116	2	5	113	2604	{}
2601	2019-12-22 19:02:07.347978	William, It Was Really Nothing	212	1	1	187	2605	{}
2602	2019-12-22 19:02:07.347978	What Difference Does It Make?	212	1	2	187	2606	{}
2603	2019-12-22 19:02:07.347978	These Things Take Time	212	1	3	187	2607	{}
2604	2019-12-22 19:02:07.347978	This Charming Man	212	1	4	187	2608	{}
2605	2019-12-22 19:02:07.347978	How Soon Is Now?	212	1	5	187	2609	{}
2606	2019-12-22 19:02:07.347978	Handsome Devil	212	1	6	187	2610	{}
2607	2019-12-22 19:02:07.347978	Hand In Glove	212	1	7	187	2611	{}
2608	2019-12-22 19:02:07.347978	Still Ill	212	1	8	187	2612	{}
2609	2019-12-22 19:02:07.347978	Heaven Knows I'm Miserable Now	212	2	1	187	2613	{}
2610	2019-12-22 19:02:07.347978	This Night Has Opened My Eyes	212	2	2	187	2614	{}
2611	2019-12-22 19:02:07.347978	You've Got Everything Now	212	2	3	187	2615	{}
2612	2019-12-22 19:02:07.347978	Accept Yourself	212	2	4	187	2616	{}
2613	2019-12-22 19:02:07.347978	Girl Afraid	212	2	5	187	2617	{}
2614	2019-12-22 19:02:07.347978	Back To The Old House	212	2	6	187	2618	{}
2615	2019-12-22 19:02:07.347978	Reel Around The Fountain	212	2	7	187	2619	{}
2616	2019-12-22 19:02:07.347978	Please Please Please Let Me Get What I Want	212	2	8	187	2620	{}
2617	2019-12-22 19:02:07.347978	Time Is On My Side	161	1	1	158	2621	{}
2618	2019-12-22 19:02:07.347978	Heart Of Stone	161	1	2	158	2622	{}
2619	2019-12-22 19:02:07.347978	Play With Fire	161	1	3	158	2623	{}
2620	2019-12-22 19:02:07.347978	(I Can't Get No) Satisfaction	161	1	4	158	2624	{}
2621	2019-12-22 19:02:07.347978	As Tears Go By	161	1	5	158	2625	{}
2622	2019-12-22 19:02:07.347978	Get Off Of My Cloud	161	1	6	158	2626	{}
2623	2019-12-22 19:02:07.347978	Mother's Little Helper	161	2	1	158	2627	{}
2624	2019-12-22 19:02:07.347978	19th Nervous Breakdown	161	2	2	158	2628	{}
2625	2019-12-22 19:02:07.347978	Paint It Black	161	2	3	158	2629	{}
2626	2019-12-22 19:02:07.347978	Under My Thumb	161	2	4	158	2630	{}
2627	2019-12-22 19:02:07.347978	Ruby Tuesday	161	2	5	158	2631	{}
2628	2019-12-22 19:02:07.347978	Let's Spend The Night Together	161	2	6	158	2632	{}
2629	2019-12-22 19:02:07.347978	Jumpin' Jack Flash	161	3	1	158	2633	{}
2630	2019-12-22 19:02:07.347978	Street Fighting Man	161	3	2	158	2634	{}
2631	2019-12-22 19:02:07.347978	Sympathy For The Devil	161	3	3	158	2635	{}
2632	2019-12-22 19:02:07.347978	Honky Tonk Woman	161	3	4	158	2636	{}
2633	2019-12-22 19:02:07.347978	Gimme Shelter	161	3	5	158	2637	{}
2634	2019-12-22 19:02:07.347978	Midnight Rambler (Live)	161	4	1	158	2638	{}
2635	2019-12-22 19:02:07.347978	You Can't Always Get What You Want	161	4	2	158	2639	{}
2636	2019-12-22 19:02:07.347978	Brown Sugar	161	4	3	158	2640	{}
2637	2019-12-22 19:02:07.347978	Wild Horses	161	4	4	158	2641	{}
2638	2019-12-22 19:02:07.347978	Smooth Operator	111	1	1	109	2642	{}
2639	2019-12-22 19:02:07.347978	Your Love Is King	111	1	2	109	2643	{}
2640	2019-12-22 19:02:07.347978	Hang On To Your Love	111	1	3	109	2644	{}
2641	2019-12-22 19:02:07.347978	Frankie's First Affair	111	1	4	109	2645	{}
2642	2019-12-22 19:02:07.347978	When Am I Going To Make A Living	111	1	5	109	2646	{}
2643	2019-12-22 19:02:07.347978	Cherry Pie	111	2	1	109	2647	{}
2644	2019-12-22 19:02:07.347978	Sally	111	2	2	109	2648	{}
2645	2019-12-22 19:02:07.347978	I Will Be Your Friend	111	2	3	109	2649	{}
2646	2019-12-22 19:02:07.347978	Why Can't We Live Together	111	2	4	109	2650	{}
2647	2019-12-22 19:02:07.347978	We No Who U R	1	1	1	3	2651	{}
2648	2019-12-22 19:02:07.347978	Wide Lovely Eyes	1	1	2	3	2652	{}
2649	2019-12-22 19:02:07.347978	Water's Edge	1	1	3	3	2653	{}
2650	2019-12-22 19:02:07.347978	Jubilee Street	1	1	4	3	2654	{}
2651	2019-12-22 19:02:07.347978	Mermaids	1	1	5	3	2655	{}
2652	2019-12-22 19:02:07.347978	We Real Cool	1	2	1	3	2656	{}
2653	2019-12-22 19:02:07.347978	Finishing Jubilee Street	1	2	2	3	2657	{}
2654	2019-12-22 19:02:07.347978	Higgs Boson Blues	1	2	3	3	2658	{}
2655	2019-12-22 19:02:07.347978	Push The Sky Away	1	2	4	3	2659	{}
2656	2019-12-22 19:02:07.347978	Get Got	41	1	1	36	2660	{}
2657	2019-12-22 19:02:07.347978	The Fever (Aye Aye)	41	1	2	36	2661	{}
2658	2019-12-22 19:02:07.347978	Lost Boys	41	1	3	36	2662	{}
2659	2019-12-22 19:02:07.347978	Black Jack	41	1	4	36	2663	{}
2660	2019-12-22 19:02:07.347978	Hustle Bones	41	1	5	36	2664	{}
2661	2019-12-22 19:02:07.347978	I've Seen Footage	41	1	6	36	2665	{}
2662	2019-12-22 19:02:07.347978	Double Helix	41	1	7	36	2666	{}
2663	2019-12-22 19:02:07.347978	System Blower	41	2	1	36	2667	{}
2664	2019-12-22 19:02:07.347978	The Cage	41	2	2	36	2668	{}
2665	2019-12-22 19:02:07.347978	Punk Weight	41	2	3	36	2669	{}
2666	2019-12-22 19:02:07.347978	Fuck That	41	2	4	36	2670	{}
2667	2019-12-22 19:02:07.347978	Bitch Please	41	2	5	36	2671	{}
2668	2019-12-22 19:02:07.347978	Hacker	41	2	6	36	2672	{}
2669	2019-12-22 19:02:07.347978	A Sort Of Homecoming	170	1	1	164	2673	{}
2670	2019-12-22 19:02:07.347978	Pride (In The Name Of Love)	170	1	2	164	2674	{}
2671	2019-12-22 19:02:07.347978	Wire	170	1	3	164	2675	{}
2672	2019-12-22 19:02:07.347978	The Unforgettable Fire	170	1	4	164	2676	{}
2673	2019-12-22 19:02:07.347978	Promenade	170	1	5	164	2677	{}
2674	2019-12-22 19:02:07.347978	4th Of July	170	2	1	164	2678	{}
2675	2019-12-22 19:02:07.347978	Bad	170	2	2	164	2679	{}
2676	2019-12-22 19:02:07.347978	Indian Summer Sky	170	2	3	164	2680	{}
2677	2019-12-22 19:02:07.347978	Elvis Presley And America	170	2	4	164	2681	{}
2678	2019-12-22 19:02:07.347978	M.L.K.	170	2	5	164	2682	{}
2679	2019-12-22 19:02:07.347978	Where Do The Children Play?	147	1	1	141	2683	{}
2680	2019-12-22 19:02:07.347978	Hard Headed Woman	147	1	2	141	2684	{}
2681	2019-12-22 19:02:07.347978	Wild World	147	1	3	141	2685	{}
2682	2019-12-22 19:02:07.347978	Sad Lisa	147	1	4	141	2686	{}
2683	2019-12-22 19:02:07.347978	Miles From Nowhere	147	1	5	141	2687	{}
2684	2019-12-22 19:02:07.347978	But I Might Die Tonight (From The Film "Deep End")	147	2	1	141	2688	{}
2685	2019-12-22 19:02:07.347978	Longer Boats	147	2	2	141	2689	{}
2686	2019-12-22 19:02:07.347978	Into White	147	2	3	141	2690	{}
2687	2019-12-22 19:02:07.347978	On The Road To Find Out	147	2	4	141	2691	{}
2688	2019-12-22 19:02:07.347978	Father & Son (From The Film "Revolussia")	147	2	5	141	2692	{}
2689	2019-12-22 19:02:07.347978	Tea For The Tillerman	147	2	6	141	2693	{}
2690	2019-12-22 19:02:07.347978	Thunder Road	192	1	1	177	2694	{}
2691	2019-12-22 19:02:07.347978	Tenth Avenue Freeze-Out	192	1	2	177	2695	{}
2692	2019-12-22 19:02:07.347978	Night	192	1	3	177	2696	{}
2693	2019-12-22 19:02:07.347978	Backstreets	192	1	4	177	2697	{}
2694	2019-12-22 19:02:07.347978	Born To Run	192	2	1	177	2698	{}
2695	2019-12-22 19:02:07.347978	She's The One	192	2	2	177	2699	{}
2696	2019-12-22 19:02:07.347978	Meeting Across The River	192	2	3	177	2700	{}
2697	2019-12-22 19:02:07.347978	Jungleland	192	2	4	177	2701	{}
2698	2019-12-22 19:02:07.347978	A Horse With No Name	125	1	1	126	2702	{}
2699	2019-12-22 19:02:07.347978	I Need You	125	1	2	126	2703	{}
2700	2019-12-22 19:02:07.347978	Sandman	125	1	3	126	2704	{}
2701	2019-12-22 19:02:07.347978	Ventura Highway	125	1	4	126	2705	{}
2702	2019-12-22 19:02:07.347978	Don't Cross The River	125	1	5	126	2706	{}
2703	2019-12-22 19:02:07.347978	Only In Your Heart	125	1	6	126	2707	{}
2704	2019-12-22 19:02:07.347978	Muskrat Love	125	2	1	126	2708	{}
2705	2019-12-22 19:02:07.347978	Tin Man	125	2	2	126	2709	{}
2706	2019-12-22 19:02:07.347978	Lonely People	125	2	3	126	2710	{}
2707	2019-12-22 19:02:07.347978	Sister Golden Hair	125	2	4	126	2711	{}
2708	2019-12-22 19:02:07.347978	Daisy Jane	125	2	5	126	2712	{}
2709	2019-12-22 19:02:07.347978	Woman Tonight	125	2	6	126	2713	{}
2710	2019-12-22 19:02:07.347978	Come To My Aid	82	1	1	85	2714	{}
2711	2019-12-22 19:02:07.347978	Sad Old Red	82	1	2	85	2715	{}
2712	2019-12-22 19:02:07.347978	Look At You Now	82	1	3	85	2716	{}
2713	2019-12-22 19:02:07.347978	Heaven	82	1	4	85	2717	{}
2714	2019-12-22 19:02:07.347978	Jericho	82	1	5	85	2718	{}
2715	2019-12-22 19:02:07.347978	Money's Too Tight (To Mention)	82	2	1	85	2719	{}
2716	2019-12-22 19:02:07.347978	Holding Back The Years	82	2	2	85	2720	{}
2717	2019-12-22 19:02:07.347978	Red Box	82	2	3	85	2721	{}
2718	2019-12-22 19:02:07.347978	No Direction	82	2	4	85	2722	{}
2719	2019-12-22 19:02:07.347978	Picture Book	82	2	5	85	2723	{}
2720	2019-12-22 19:02:07.347978	Burnout	158	1	1	151	2724	{}
2721	2019-12-22 19:02:07.347978	Having A Blast	158	1	2	151	2725	{}
2722	2019-12-22 19:02:07.347978	Chump	158	1	3	151	2726	{}
2723	2019-12-22 19:02:07.347978	Longview	158	1	4	151	2727	{}
2724	2019-12-22 19:02:07.347978	Welcome To Paradise	158	1	5	151	2728	{}
2725	2019-12-22 19:02:07.347978	Pulling Teeth	158	1	6	151	2729	{}
2726	2019-12-22 19:02:07.347978	Basket Case	158	1	7	151	2730	{}
2727	2019-12-22 19:02:07.347978	She	158	2	1	151	2731	{}
2728	2019-12-22 19:02:07.347978	Sassafras Roots	158	2	2	151	2732	{}
2729	2019-12-22 19:02:07.347978	When I Come Around	158	2	3	151	2733	{}
2730	2019-12-22 19:02:07.347978	Coming Clean	158	2	4	151	2734	{}
2731	2019-12-22 19:02:07.347978	Emenius Sleepus	158	2	5	151	2735	{}
2732	2019-12-22 19:02:07.347978	In The End	158	2	6	151	2736	{}
2733	2019-12-22 19:02:07.347978	F.O.D.	158	2	7	151	2737	{}
2734	2019-12-22 19:02:07.347978	All By Myself	158	2	8	151	2738	{}
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, created_at, first_name, second_name, email, country_code) FROM stdin;
1	2019-12-22 11:47:03.733118	Arthur	Petukhovsky	petuhovskiy@yandex.ru	RU
2	2019-12-22 11:55:03.021619	John	Smith	johnsmith@example.com	US
3	2019-12-22 11:55:03.55103	Vasiliy	Nikolaev	vasiliy@tut.by	BY
4	2019-12-22 19:24:21.040261	Andrey	Melomanovich	andrey@melom.ch	RU
\.


--
-- Name: albums_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.albums_id_seq', 225, true);


--
-- Name: artists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.artists_id_seq', 201, true);


--
-- Name: labels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.labels_id_seq', 81, true);


--
-- Name: mediafiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mediafiles_id_seq', 2738, true);


--
-- Name: tracks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tracks_id_seq', 2734, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


--
-- Name: albums_countries albums_countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums_countries
    ADD CONSTRAINT albums_countries_pkey PRIMARY KEY (album_id, country_code);


--
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- Name: artists artists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.artists
    ADD CONSTRAINT artists_pkey PRIMARY KEY (id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: library library_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_pkey PRIMARY KEY (user_id, track_id);


--
-- Name: mediafiles mediafiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mediafiles
    ADD CONSTRAINT mediafiles_pkey PRIMARY KEY (id);


--
-- Name: tracks tracks_album_id_disc_id_position_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_album_id_disc_id_position_id_key UNIQUE (album_id, disc_id, position_id);


--
-- Name: tracks tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: library check_country_restr; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_country_restr AFTER INSERT OR DELETE OR UPDATE ON public.library FOR EACH ROW EXECUTE FUNCTION public.check_country_restr();


--
-- Name: library check_library_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_library_limit AFTER INSERT OR DELETE OR UPDATE ON public.library FOR EACH ROW EXECUTE FUNCTION public.check_library_limit();


--
-- Name: albums albums_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albums_countries albums_countries_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums_countries
    ADD CONSTRAINT albums_countries_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albums_countries albums_countries_country_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums_countries
    ADD CONSTRAINT albums_countries_country_code_fkey FOREIGN KEY (country_code) REFERENCES public.countries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: albums albums_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_label_id_fkey FOREIGN KEY (label_id) REFERENCES public.labels(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: library library_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.tracks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: library library_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.library
    ADD CONSTRAINT library_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tracks tracks_album_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_album_id_fkey FOREIGN KEY (album_id) REFERENCES public.albums(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tracks tracks_artist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES public.artists(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: tracks tracks_mediafile_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tracks
    ADD CONSTRAINT tracks_mediafile_id_fkey FOREIGN KEY (mediafile_id) REFERENCES public.mediafiles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: users users_country_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_country_code_fkey FOREIGN KEY (country_code) REFERENCES public.countries(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

