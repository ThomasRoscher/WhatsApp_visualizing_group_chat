library(lubridate) # working with dates
library(tidyverse) # data manipulation
library(stringr)   # working with strings
library(tm)        # text mining
library(wordcloud) # word cloud plot

##### READ DATA #####

# read each line of the txt
wirtshaus       <- readLines ("wirtshaus.txt", encoding="UTF-8")
# split line into time and rest
time.stamp            <- sapply(strsplit(wirtshaus, split=" - "), "[", 1)
time.stamp            <- dmy_hm(time.stamp) 
person_text     <- sapply(strsplit(wirtshaus, split=" - "), "[", 2)
# split rest into person and text
person          <- sapply(strsplit(person_text, split=": "), "[", 1)
text            <- sapply(strsplit(person_text, split=": "), "[", 2)
# combine in data frame
wirtshaus.df    <- as.data.frame(cbind(format(time.stamp), person, text))
wirtshaus.df    <- arrange(wirtshaus.df,person)
wirtshaus.df$ID <- seq.int(nrow(wirtshaus.df))


##### ADJUST CLASSES AND NAs #####

wirtshaus.df <- wirtshaus.df %>%
  # time to POSIXct
  mutate(time.stamp = ymd_hms(V1)) %>%
  # person and text to character 
  mutate(person = as.character(person)) %>%
  mutate(text = as.character(text)) %>%
  select(-V1) %>%
  # drop NAs variable "time"
  filter(!is.na(time.stamp))

##### ADJUST PERSON #####

# drop useless values variable "person"
wirtshaus.df  <- wirtshaus.df %>%
  filter(!grepl("hinzugefügt",person)) %>%
  filter(!grepl("gewechselt",person)) %>%
  filter(!grepl("Betreff",person)) %>%
  filter(!grepl("Ende-zu-Ende",person)) %>%
  filter(!grepl("Gruppenbild",person)) %>%
  filter(!grepl("verlassen",person)) %>%
  filter(!grepl("entfernt",person)) %>%
  filter(!grepl("NA",person)) %>%
  filter(!is.na(person))


# assign old number to persons 
wirtshaus.df <- wirtshaus.df %>%
        mutate(person = replace(person, person =="+49 1511 4953993", "NoIdea")) %>%
        mutate(person = replace(person, person =="+49 1516 5172467", "Franci")) %>%
        mutate(person= replace(person, person =="+49 1517 5006517", "Basti")) %>%
        mutate(person = replace(person, person =="+49 1522 6853144", "Tommy")) %>%
        mutate(person = replace(person, person =="+49 1575 1257878", "NoIdea")) %>%
        mutate(person= replace(person, person =="+49 162 5408821", "Martin")) %>%
        mutate(person= replace(person, person =="+49 163 1805235",  "Jule")) %>%
        mutate(person= replace(person, person =="*+49 170 9094676",  "Tim")) %>%
        mutate(person= replace(person, person =="+49 176 61528706",  "Tommy"))%>%
        mutate(person= replace(person, person =="+49 176 62617429",  "Jan")) %>%
        mutate(person= replace(person, person =="+49 176 63428924,",  "Steffke")) %>%
        mutate(person= replace(person, person =="*+49 176 97869992",  "Joy")) %>%
        mutate(person= replace(person, person =="+49 176 98288229",  "Rike"))

# use id to assign old numbers
wirtshaus.df$Person <- NA
wirtshaus.df$Person [wirtshaus.df$ID < 127] <- "Joy"
wirtshaus.df$Person [wirtshaus.df$ID > 127  & wirtshaus.df$ID < 2008] <- "Franci"
wirtshaus.df$Person [wirtshaus.df$ID > 2006 & wirtshaus.df$ID < 4391] <- "Basti"
wirtshaus.df$Person [wirtshaus.df$ID > 4389 & wirtshaus.df$ID < 4791] <- "Tommy"
wirtshaus.df$Person [wirtshaus.df$ID > 4789 & wirtshaus.df$ID < 4890] <- "noIdea"
wirtshaus.df$Person [wirtshaus.df$ID > 4889 & wirtshaus.df$ID < 4921] <- "Martin"
wirtshaus.df$Person [wirtshaus.df$ID > 4918 & wirtshaus.df$ID < 4949] <- "Jule"
wirtshaus.df$Person [wirtshaus.df$ID > 4947 & wirtshaus.df$ID < 4992] <- "Tim"
wirtshaus.df$Person [wirtshaus.df$ID > 4991 & wirtshaus.df$ID < 5231] <- "Tommy"
wirtshaus.df$Person [wirtshaus.df$ID > 5229 & wirtshaus.df$ID < 5251] <- "Jan"
wirtshaus.df$Person [wirtshaus.df$ID > 5249 & wirtshaus.df$ID < 5348] <- "Steffke"
wirtshaus.df$Person [wirtshaus.df$ID > 5346 & wirtshaus.df$ID < 5626] <- "Joy"
wirtshaus.df$Person [wirtshaus.df$ID > 5624 & wirtshaus.df$ID < 5748] <- "Rike"

wirtshaus.df <- wirtshaus.df %>%
        mutate(Person = ifelse(is.na(Person), person, Person))

# who wrote the most messages
messages.aggregated.people <- wirtshaus.df %>% 
        group_by(Person) %>% 
        summarise(Count = n()) %>% 
        arrange(desc(Count))

p1 <- ggplot(data=messages.aggregated.people, aes(x = reorder(Person, Count), y=Count)) +
        geom_bar(stat="identity", color ="steelblue", fill = "white") + 
        ggtitle("Wirtshaus: Nachrichten pro Gruppenmitglied") +
        xlab("") + 
        ylab("") +
        geom_text(aes(label=Count), vjust = -0.4, position = position_dodge(.9), size = 2) +
        theme(axis.text.x = element_text(angle = 90, hjust = 1))

# messages over date
messages.aggregated.date <- wirtshaus.df %>%
        mutate(date = format(as.Date(time.stamp), "%Y-%m")) %>%
        group_by(date) %>% 
        summarise(Count = n()) 


p2 <- ggplot(messages.aggregated.date, aes(date, Count, group =1)) + 
  geom_line(color = "steelblue") +
  geom_point() + 
  ggtitle("Wirtshaus: Monatliche Nachrichten (2014/06 - 2017/04)") +
  xlab("") + 
  ylab("") +
  geom_text(aes(label=Count), vjust = -0.4, position = position_dodge(.9), size = 3) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# messages over day
messages.aggregated.day <- wirtshaus.df %>%
        mutate(day = wday(time.stamp, label=TRUE, abbr=FALSE)) %>%
        group_by(day) %>% 
        summarise(Count = n()) 

p3 <- ggplot(messages.aggregated.day, aes(x = reorder(day, Count), y=Count)) +
  geom_bar(stat="identity", color ="steelblue", fill = "white") + 
  ggtitle("Wirtshaus: Nachrichten pro Wochentag") +
  xlab("") + 
  ylab("") +
  geom_text(aes(label=Count), vjust = -0.4, position = position_dodge(.9), size = 3) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# messages over time
messages.aggregated.time <- wirtshaus.df %>%
        mutate(time = format(time.stamp,'%H')) %>%
        group_by(time) %>% 
        summarise(Count = n())

p4 <- ggplot(messages.aggregated.time, aes(x = time, y=Count)) +
  geom_bar(stat="identity", color ="steelblue", fill = "white") + 
  ggtitle("Wirtshaus: Nachrichten pro Stunde") +
  xlab("") + 
  ylab("") +
  geom_text(aes(label=Count), vjust = -0.4, position = position_dodge(.9), size = 3) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# emoticons and pictures 
wirtshaus.df$picture <- 0
flag <- str_detect(wirtshaus.df$text, "<Medien weggelassen>")
wirtshaus.df <- cbind(wirtshaus.df, flag)
wirtshaus.df <- wirtshaus.df %>%
        mutate(picture = ifelse(flag == TRUE, 1, picture))

wirtshaus.df$Text.Cleaned <- sapply(wirtshaus.df$text, 
                                function(row) iconv(row, "UTF-8", sub = ""))

wirtshaus.df <- wirtshaus.df %>%
mutate(emo = ifelse(text == Text.Cleaned, 0, 1)) 

wirtshaus.df$Type <- "Nur Text"
wirtshaus.df$Type[wirtshaus.df$emo == 1] <- "Emoticon"
wirtshaus.df$Type[wirtshaus.df$picture == 1] <- "Bild"
wirtshaus.df$Type <- as.factor(wirtshaus.df$Type)

messages.aggregated.type <- wirtshaus.df %>%
  group_by(Type) %>% 
  summarise(Count = n())


p5 <- ggplot(data=messages.aggregated.type, aes(x = reorder(Type, Count), y=Count)) +
  geom_bar(stat="identity", color ="steelblue", fill = "white") + 
  ggtitle("Wirtshaus: Nachrichten nach Type") +
  xlab("") + 
  ylab("") +
  coord_flip()


# text analysis
text_all <- as.character(wirtshaus.df$Text.Cleaned)
text_all <- str_replace_all(text_all, "<Medien weggelassen>", " ")

ap.corpus = Corpus(DataframeSource(data.frame(text_all)))
ap.corpus = tm_map(ap.corpus, removePunctuation)
ap.corpus = tm_map(ap.corpus, content_transformer(tolower))
ap.corpus = tm_map(ap.corpus, function(x) removeWords(x, c(stopwords("german"), "sowie","dass","bzw")))

ap.tdm = TermDocumentMatrix(ap.corpus)
ap.m = as.matrix(ap.tdm)
ap.v = sort(rowSums(ap.m),decreasing=TRUE)
ap.d = data.frame(word = names(ap.v),freq=ap.v)

pal2 = brewer.pal(8,"Dark2")

wordcloud(words =  ap.d$word, freq = ap.d$freq, min.freq = 1,
          max.words=150, random.order=FALSE, rot.per=0.35, 
          colors=brewer.pal(8, "Dark2"))





