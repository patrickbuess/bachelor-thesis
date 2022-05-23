-- Create initial empty database

-- drop table raw_gdelt;
-- drop table raw_elections;
-- drop table proc_elections;
-- drop table proc_gdelt;
-- drop table temp_gdelt;
-- drop table countries;
-- drop table bil_relationships; 
-- drop table gdelt_datatypes;

create table temp_gdelt (
	id serial primary key,
	event_id int,
	month int,
	year int,
	date int,
	country_1 varchar(10) default null,
	country_2 varchar(10) default null,
	type_1 varchar(10) default null,
	type_2 varchar(10) default null,
	name_1 varchar(100) default null,
	name_2 varchar(100) default null,
	root_event int default 0,
	action varchar(10) default null,
	quad_class int default null,
	tone float default null,
	num_mentions int default null,
	num_sources int default null,
	num_articles int default null,
	source varchar(500) default null
);

create table raw_elections (
	id serial primary key,
	country_name varchar(50) default null,
	iso_code varchar(3) default null,
	date date default null,
	system varchar(50) default null,
	years_inoffice float default null,
	percent_first_round float default null,
	percent_final_round float default null,
	leaning varchar(20) default null,
	reelectable float default null,
	allhouse float default null
);

create table countries (
	id serial primary key,
	iso_code varchar(3) default null,
	name varchar(50) default null
);

create table bil_relationships (
	id serial primary key,
	country int not null,
	partner int not null,
	foreign key (country) references countries (id),
	foreign key (partner) references countries (id)
);

create table proc_elections (
	id serial primary key,
	gov_period varchar(8) not null,
	country int not null,
	year int not null,
	election boolean default false,
	"right" boolean default false,
	center boolean default false,
	"left" boolean default false,
	years_inoffice int default null,
	change float default 0,
	foreign key (country) references countries (id)
);


create table gdelt_datatypes (
	id serial primary key,
	type_name varchar(100)
);

insert into gdelt_datatypes (type_name) values ('All data');
insert into gdelt_datatypes (type_name) values ('GOV data');
insert into gdelt_datatypes (type_name) values ('Multi source');

create table proc_gdelt (
	id serial primary key,
	relation_id int not null,
	tone float not null,
	growth float default null,
	year int not null,
	data_type int not null,
	foreign key (data_type) references gdelt_datatypes (id),
	foreign key (relation_id) references bil_relationships (id)
);

create table ref_avg_tones (
	id serial primary key,
	year int not null,
	tone float not null,
	data_type int not null,
	foreign key (data_type) references gdelt_datatypes (id)
);


