# Here are the data for the project:
# https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

#download the data:
#url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
#download.file(url, "dataFiles.zip")
#unzip(zipfile = "dataFiles.zip")

library('data.table')
library('reshape2')
path <- getwd()
path
# Load activity labels + features

labels <- fread(file.path(path, "UCI HAR Dataset/activity_labels.txt")
                , col.names = c("labels", "activityname"))
head(labels)

features <- fread(file.path(path, "UCI HAR Dataset/features.txt")
                  , col.names = c("index", "featurenames"))

head(features)

# Extracts only the measurements on the mean and standard deviation for each measurement.
# Features info: 
# The set of variables that were estimated from these signals are: 
# mean(): Mean value
# std(): Standard deviation

newfeatures <- grep("(mean|std)\\(\\)", features[, featurenames])

measurements <- features[newfeatures, featurenames]
#measurements

measurements <- gsub('[()]', '', measurements)
#measurements


# Merges the training and the test sets to create one data set.
# Load train datasets

train <- fread(file.path(path, "UCI HAR Dataset/train/X_train.txt"))[, newfeatures, with = FALSE]

data.table::setnames(train, colnames(train), measurements)

activities.train <- fread(file.path(path, "UCI HAR Dataset/train/Y_train.txt")
                          , col.names = c("Activity"))
#str(trainActivities)

subjects.train <- fread(file.path(path, "UCI HAR Dataset/train/subject_train.txt")
                        , col.names = c("SubjectNum"))

train <- cbind(subjects.train, activities.train, train)
str(train)
length(train)

# Load test datasets
test <- fread(file.path(path, "UCI HAR Dataset/test/X_test.txt"))[, newfeatures, with = FALSE]
data.table::setnames(test, colnames(test), measurements)
activities.test <- fread(file.path(path, "UCI HAR Dataset/test/Y_test.txt")
                         , col.names = c("Activity"))
#head(activities.test)
subjects.test <- fread(file.path(path, "UCI HAR Dataset/test/subject_test.txt")
                       , col.names = c("SubjectNum"))
#str(subjects.test)
test <- cbind(subjects.test, activities.test, test)
#head(test)
#str(test)
#length(test)

# merge datasets
merge.data <- rbind(train, test)
str(merge.data)

# the same length was obtained
#length(merge.data)

# Convert classLabels to activityName basically. More explicit. 
# from int to factor
# from: $ Activity : int  5 5 5 5 5 5 5 5 5 5 ...
# to  : $ Activity : Factor w/ 0 levels: NA NA NA NA NA NA NA NA NA NA ...

merge.data[["Activity"]] <- factor(merge.data[, Activity]
                                   , levels = labels[["classLabels"]]
                                   , labels = labels[["activityName"]])

#From  : $ SubjectNum : int  1 1 1 1 1 1 1 1 1 1 ...
#to    : $ SubjectNum : Factor w/ 30 levels "1","2","3","4",..: 1 1 1 1 1 1 1 1 1 1 ...

merge.data[["SubjectNum"]] <- as.factor(merge.data[, SubjectNum])

merge.data <- reshape2::melt(data = merge.data, id = c("SubjectNum", "Activity"))
merge.data <- reshape2::dcast(data = merge.data, SubjectNum + Activity ~ variable, fun.aggregate = mean)

data.table::fwrite(x = merge.data, file = "tidy_final.txt", quote = FALSE)
