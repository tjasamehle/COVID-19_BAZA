library(dplyr)
library(dbplyr)
library(RPostgreSQL)

setwd("~/OPB-shiny/app")
source("auth.R")
setwd("~/OPB-shiny/uvoz")
source("tabele.R", encoding = "UTF-8")



drv <- dbDriver("PostgreSQL")


delete_table <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
    
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS bolnik CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS ima CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS lokacije CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS oseba CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS simptom CASCADE", con=conn))
    dbSendQuery(conn,build_sql("DROP TABLE IF EXISTS zd_delavec_na_dolznosti CASCADE", con=conn))
    
  }, finally = {
    dbDisconnect(conn)
  })
}

ustvari_tabele <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host,
                      user = user, password = password)
    
    oseba <- dbSendQuery(conn, build_sql("CREATE TABLE oseba (
                                         ime text,
                                         davcna_st bigserial PRIMARY KEY,
                                         naslov text,
                                         datum_testiranja date,
                                         stanje text)", con=conn))
    
    simptom <- dbSendQuery(conn, build_sql("CREATE TABLE simptom (
                                           id bigserial PRIMARY KEY,
                                           simptom text)", con=conn))
    
    lokacije <- dbSendQuery(conn, build_sql("CREATE TABLE lokacije (
                                       id bigserial PRIMARY KEY,
                                       lokacija text,
                                       st_postelj integer,
                                       st_zdravnikov integer)", con=conn))
    
    
    ima <- dbSendQuery(conn, build_sql("CREATE TABLE ima (
                                              id_pacienta bigint REFERENCES oseba(davcna_st),
                                              id_simptomi bigint REFERENCES simptom(id),
                                              jakost integer,
                                              datum_pojavitve date,
                                              PRIMARY KEY (id_pacienta, id_simptomi))", con=conn))
    
    
    
    bolnik <- dbSendQuery(conn, build_sql("CREATE TABLE bolnik (
                                             id_bolnika bigint REFERENCES oseba(davcna_st),
                                             id_zdravnika bigint REFERENCES oseba(davcna_st),
                                             hospitalizacija numeric,
                                             PRIMARY KEY (id_bolnika))", con=conn))
    
    
    zd_delavec_na_dolznosti <- dbSendQuery(conn, build_sql("CREATE TABLE zd_delavec_na_dolznosti (
                                          id bigint REFERENCES oseba(davcna_st),
                                          zd_ustanova_id_c bigserial REFERENCES lokacije(id),
                                          PRIMARY KEY (id))", con=conn))
    
    credentials <- dbSendQuery(conn, build_sql("CREATE TABLE credentials (
                                          username_id text PRIMARY KEY,
                                          password text,
                                          permission text,
                                          stringsAsFactors text)", con=conn))
    
    
   }, finally = {
    dbDisconnect(conn)
  })
}


credentials = data.frame(
  username_id = c("jan", "aljosa","filip","gost"),
  password   = sapply(c("opb", "opb","opb","gost"),password_store),
  permission  = c("advanced", "advanced","advanced","basic"), 
  stringsAsFactors = F
)

insert_data <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host, user = user, password = password)
    
    dbWriteTable(conn, name="oseba", oseba, append=T, row.names=FALSE)
    dbWriteTable(conn, name="simptom", simptom, append=T, row.names=FALSE, encoding = "UTF-8")
    dbWriteTable(conn, name="lokacije", lokacije, append=T, row.names=FALSE)
    dbWriteTable(conn, name="ima", ima, append=T, row.names=FALSE)
    dbWriteTable(conn, name="bolnik", bolnik, append=T, row.names=FALSE)
    dbWriteTable(conn, name="zd_delavec_na_dolznosti", zd_delavec_na_dolznosti, append=T, row.names=FALSE)
    dbWriteTable(conn, name="credentials", credentials, append=T, row.names=FALSE)

  }, finally = {
    dbDisconnect(conn) 
    
  })
}

pravice <- function(){
  tryCatch({
    conn <- dbConnect(drv, dbname = db, host = host,
                      user = user, password = password)
    
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_jank TO jank WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_jank TO javnost WITH GRANT OPTION", con=conn))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO filipn WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON SCHEMA public TO aljosar WITH GRANT OPTION", con=conn))
    
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO filipn WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO aljosar WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO jank WITH GRANT OPTION", con=conn))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO filipn WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO aljosar WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO jank WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO javnost", con=conn))
    
    dbSendQuery(conn, build_sql("GRANT CONNECT ON DATABASE sem2020_jank TO javnost", con=conn))
    dbSendQuery(conn, build_sql("GRANT SELECT ON ALL TABLES IN SCHEMA public TO javnost", con=conn))
    dbSendQuery(conn, build_sql("GRANT INSERT ON ALL TABLES IN SCHEMA public TO javnost", con = conn))
    dbSendQuery(conn, build_sql("GRANT UPDATE ON ALL TABLES IN SCHEMA public TO javnost", con = conn))  
    
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO filipn WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL TABLES IN SCHEMA public TO aljosar WITH GRANT OPTION", con=conn))
    
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO filipn WITH GRANT OPTION", con=conn))
    dbSendQuery(conn, build_sql("GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO aljosar WITH GRANT OPTION", con=conn))
    
  }, finally = {
    dbDisconnect(conn) 
  })
}


delete_table()
ustvari_tabele()
insert_data()
pravice()