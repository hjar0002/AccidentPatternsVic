library(shiny)
library(viridis)
library(randomForest)
library(dplyr)
library(tidyr)
library(ggplot2) # Used for plotting the correlations
library(Metrics) # Used for calculating root mean squared log error
library(caret)  # For data partition
library(rpart)
library(rpart.plot)
library(shinycustomloader)
library(DT)

library(ElemStatLearn)
#dyn.load('/Library/Java/JavaVirtualMachines/jdk1.8.0_66.jdk/Contents/Home/jre/lib/server/libjvm.dylib')
library(rJava)
library(FSelector)

library(shinydashboard)
#setting dashboard theme
theme_set(theme_classic())
###################################################
df1<-read.csv('SummaryQuery.csv')
df<-df1[,-c(1,5,10,11,12,22,23)]
options(warn=-1)


df<-df %>% rename("Month" = "MONTH","TimeRange" = "Time_Zone", "WeekDay" = "DAY.WEEK.DESCRIPTION",
                  "LightCondition"="LIGHT.CONDITION.DESC","RoadGeometry" = "Road.Geometry.Desc",
                  "SpeedZone"="SPEED_ZONE",
                  #"Region"="DEG.URBAN.NAME", "SubRegion" = "REGION.NAME" ,
                  "Age"="AGE",
                  "SeatingPosition"="SEATING_POSITION","SeatBelt" ="HELMET_BELT_WORN",
                  "VehicleType"="VEHICLE.TYPE.DESC","TrafficControl"="TRAFFIC.CONTROL.DESC" ,
                  "RoadUser" = "ROAD.USER.TYPE.DESC","RoadSurface" = "Road_Surface_Cond",
                  "AtomsphericCondition"=  "Atmospheric_Condition", "EventType" ="Event.Type.Desc"
)


yearList = sort(unique(df1$YEAR),decreasing = TRUE)

# 
# regionList = unique(df1$Region)

ui = dashboardPage( skin ="blue",
                    dashboardHeader(
                      title ="Hidden Patterns",
                      titleWidth =200
                    ), 
                    dashboardSidebar(disable = FALSE,width = 200,
                                     sidebarMenu(
                                       menuItem("Important Factors",tabName = "menu1"),
                                       menuItem("Decision Tree",tabName = "menu2")
                                       
                                     )
                    ),
                    dashboardBody(
                      
                      #css
                      
                      tags$head(tags$style(HTML('
                                                .content{
                                                padding-top :3px;}

                                                .dashboardHeaderr .logo {
                                                font-family: "Georgia";
                                                font-weight: 800;
                                                line-height: 1.1;

                                                color: black;
                                                }
                                               
                                                }
                                                h3{
                                                
                                                font-weight: 800;
                                                font-family: "Georgia";
                                                line-height: 1.1;
                                                color: black;
                                                
                                                }
                                                
                                                .img-local{
                                                align :right;
                                                }
                                                
                                                '))),
                      #creating different tabs 
                      tabItems(
                        tabItem(tabName ="menu1",
                                h3("Road Accident Analysis - Important Factors "),
                                fluidRow(
                                  
                                  column(width =3,
                                         box(title ="Filter", solidHeader = T, status ="primary",width = 100, 
                                             selectInput(inputId = "ySelected","Year",choices = yearList,selected = "2013")   
                                         )),
                                  column(width =9, 
                                         box(  width =100,
                                              #plotOutput("VariableImp")
                                              withLoader(plotOutput("VariableImp"), type='image', loader='Spinner.gif')
                                         ),
                                         box( 
                                              width =100,
                                              withLoader(DT::dataTableOutput("mytable"), type='image', loader='Spinner.gif')
                                         )
                                         
                                  )
                                ),
                                h4(em("One of the most important indications of safety is that parents with their kids can travel safe using comfortable means of transportation.
                                    For this reason, there is a need for understanding the accidents involved in the country. From the analysis of VICROADS crash data,
                                    we have picked certain factors that are contributing during an accident. Hourly, daily, monthly and annual variations in expected traffic flow are
                                    important in the determination of road standards. There are some accepted changes in traffic flow; 
                                    for example, traffic is more dense during daylight than it is at night; during holidays traffic is more dense out of cities than it is within cities;
                                    but on weekdays it is more crowded within city than it is out of cities; and there are more vehicles on roads in summer months than in winter months. 
                                    In this study, about 30,000 kids  accidents that occurred in Victoria from 2007 are reviewed according to their time of occurrence, and  the relationship 
                                    between number of accidents and occurrence times is examined. Finally, in order to prevent accidents, possible patterns are observed 
                                    and considering that relationship we can plan the trip with kids.We have ranked the factors that can contribute for an accident.
                                    Additionally, the decision tree in the next tab gives the relation between these ranked factors with their correlation factors.")
                        )),
                        
                        tabItem(tabName ="menu2",
                                h3("Road Accident Analysis - Decision Tree"),
                                fluidRow(
                                  # column(width =2,
                                  #        box(title ="Severity Scale", solidHeader = T, status ="primary",width = 100
                                  #            
                                  #        )),
                                  column(width =12, 
                                         box( title ="Decision Tree", solidHeader = T, status ="primary", width =250,height = 500,
                                              #plotOutput("Tree")
                                              withLoader(plotOutput("Tree"), type='image', loader='Spinner.gif')
                                              
                                              
                                              
                                         )),
                                  
                                  
                                  h4("First Number in Hexagon represents  the Serverity scale(1-Very High Severe 2-High Severe 3- Less Severe ), Second Number
                                     represents the Data Ratio(Splitted between left and right node)"),
 

 
                                     h5(em("Decision Tree's are important because they could be used to extract the potentially useful information from the data.
                                     The rules have the form of logic conditional: if “A” then “B”, where “A” is the antecedent (a state or a set of statuses of one or several variables)
                                     and “B” is the consequent (one status of the variable class).
                                     So, the conditioned structure (IF) of Decision Tree, begins in root node. Each variable that intervenes in tree division makes an IF of the rule, 
                                     which ends in child nodes with a value of THEN, which is associated with the class resulting (the status of the variable class that shows
                                     the highest number of cases in the terminal node) from the child node.
                                     "))
                                  
                                  
                                  )
                                
                        )
                      )
                      ))






###################################################

server<-function(input, output){
  

  output$VariableImp = renderPlot({
    
    df <-df[df$YEAR == input$ySelected,]
    if (input$ySelected=='2017') {
      var_importance <- readRDS("var_imp_2017.rds")
    }
    else if (input$ySelected=='2016') {
      var_importance <- readRDS("var_imp_2016.rds")
    }
    else if (input$ySelected=='2015') {
      var_importance <- readRDS("var_imp_2015.rds")
    }
    else if (input$ySelected=='2014') {
      var_importance <- readRDS("var_imp_2014.rds")
    }
    else if (input$ySelected=='2013') {
      var_importance <- readRDS("var_imp_2013.rds")
    }
    else if (input$ySelected=='2012') {
      var_importance <- readRDS("var_imp_2012.rds")
    }
    else if (input$ySelected=='2011') {
      var_importance <- readRDS("var_imp_2011.rds")
    }
    else if (input$ySelected=='2010') {
      var_importance <- readRDS("var_imp_2010.rds")
    }
    else if (input$ySelected=='2009') {
      var_importance <- readRDS("var_imp_2009.rds")
    }
    else if (input$ySelected=='2008') {
      var_importance <- readRDS("var_imp_2008.rds")
    }

    else (var_importance <- readRDS("var_imp_2007.rds"))
    
    
    # fit=randomForest(factor(SEVERITY)~., data=df)
    # 
    # 
    # set.seed(42)
    # 
    # # Extracts variable importance (Mean Decrease in Gini Index)
    # # Sorts by variable importance and relevels factors to match ordering
    # var_importance <- data_frame(variable=setdiff(colnames(df), "SEVERITY")
    #                              ,importance=as.vector(importance(fit)))
    # 
    # var_importance <- arrange(var_importance, desc(importance))
    # var_importance$variable <- factor(var_importance$variable, levels=var_importance$variable)
    # 
    # var_importance%>% 
    #   filter(importance>1)%>%
    #   select(variable,importance)
    # head(var_importance,10)
    
    ggplot((var_importance), aes(x=variable, weight=importance, fill=variable)) + geom_bar() +
      ggtitle("         Important Factors from Analysis")+ xlab("Factors") +
      ylab("Imporant Factors (Score Index)")+
      scale_fill_discrete(name="Factors Name")+
      theme(axis.text.x=element_blank(),
            axis.text.y=element_text(size=12),
            axis.title=element_text(size=16),
            plot.title=element_text(size=18),
            legend.title=element_text(size=16),
            legend.text=element_text(size=12))
    
    
    
  })
  
  ###################################################    
  output$mytable = renderDataTable({
    
    df <-df[df$YEAR == input$ySelected,]
    # fit=randomForest(factor(SEVERITY)~., data=df)
    # var_importance <- data_frame(variable=setdiff(colnames(df), "SEVERITY")
    #                              ,importance=as.vector(importance(fit)))
    # 
    # var_importance <- arrange(var_importance, desc(importance))
    # var_importance$variable <- factor(var_importance$variable, levels=var_importance$variable)
    # var_importance
    # var_importance[,-1] <-round(var_importance[,-1],0)
    # colnames(var_importance)
    # var_importance$variable<- as.character(var_importance$variable)
    # var_importance$importance<- as.numeric(var_importance$importance)
    # 
    # var_importance%>% 
    #   filter(importance>1)%>%
    #   select(variable,importance)
    #
    if (input$ySelected=='2017') {
      var_importance <- readRDS("var_imp_2017.rds")
    }
    else if (input$ySelected=='2016') {
      var_importance <- readRDS("var_imp_2016.rds")
    }
    else if (input$ySelected=='2015') {
      var_importance <- readRDS("var_imp_2015.rds")
    }
    else if (input$ySelected=='2014') {
      var_importance <- readRDS("var_imp_2014.rds")
    }
    else if (input$ySelected=='2013') {
      var_importance <- readRDS("var_imp_2013.rds")
    }
    else if (input$ySelected=='2012') {
      var_importance <- readRDS("var_imp_2012.rds")
    }
    else if (input$ySelected=='2011') {
      var_importance <- readRDS("var_imp_2011.rds")
    }
    else if (input$ySelected=='2010') {
      var_importance <- readRDS("var_imp_2010.rds")
    }
    else if (input$ySelected=='2009') {
      var_importance <- readRDS("var_imp_2009.rds")
    }
    else if (input$ySelected=='2008') {
      var_importance <- readRDS("var_imp_2008.rds")
    }
    
    else (var_importance <- readRDS("var_imp_2007.rds"))
    
    var_importance$importance<-round(var_importance$importance) 
    
    max_val<-max(var_importance$importance)
    
    
    var_importance$Contribution <- cut(var_importance$importance, breaks = c(1,max_val/6,max_val/3.5,max_val/2.3,max_val),
                                       labels=c("Low","Moderate","High","Very High"))
    
    names(var_importance)[names(var_importance) == 'variable'] <- 'Factors'
    
    names(var_importance)[names(var_importance) == 'importance'] <- 'Importance'
    var_importance$"Derived Rank" = 1:nrow(var_importance)
    
    datatable(var_importance[,c(4,1,3,2)],rownames =FALSE
              ,options = list(pageLength = 5, 
                              lengthMenu = c(5,10,15,20 ), paging = T,searching = FALSE,colReorder = TRUE,
                              columnDefs = list(list(className = 'dt-right', targets = "_all"))
              )
    )
    
    
    
  })  
  
  
  output$Tree = renderPlot({
    
    df <-df[df$YEAR == input$ySelected,]
    
    
    # fit=randomForest(factor(SEVERITY)~., data=df)
    # 
    # 
    # set.seed(42)
    # 
    # # Extracts variable importance (Mean Decrease in Gini Index)
    # # Sorts by variable importance and relevels factors to match ordering
    # var_importance <- data_frame(variable=setdiff(colnames(df), "SEVERITY")
    #                              ,importance=as.vector(importance(fit)))
    # 
    # var_importance <- arrange(var_importance, desc(importance))
    # var_importance$variable <- factor(var_importance$variable, levels=var_importance$variable)
    if (input$ySelected=='2017') {
      var_importance <- readRDS("var_imp_2017.rds")
    }
    else if (input$ySelected=='2016') {
      var_importance <- readRDS("var_imp_2016.rds")
    }
    else if (input$ySelected=='2015') {
      var_importance <- readRDS("var_imp_2015.rds")
    }
    else if (input$ySelected=='2014') {
      var_importance <- readRDS("var_imp_2014.rds")
    }
    else if (input$ySelected=='2013') {
      var_importance <- readRDS("var_imp_2013.rds")
    }
    else if (input$ySelected=='2012') {
      var_importance <- readRDS("var_imp_2012.rds")
    }
    else if (input$ySelected=='2011') {
      var_importance <- readRDS("var_imp_2011.rds")
    }
    else if (input$ySelected=='2010') {
      var_importance <- readRDS("var_imp_2010.rds")
    }
    else if (input$ySelected=='2009') {
      var_importance <- readRDS("var_imp_2009.rds")
    }
    else if (input$ySelected=='2008') {
      var_importance <- readRDS("var_imp_2008.rds")
    }
    
    else (var_importance <- readRDS("var_imp_2007.rds"))
    
    
    
    
    # first remember the names
    names <- var_importance$variable
    
    # transpose all but the first column (name)
    transpose <- as.data.frame(t(var_importance[,-1]))
    colnames(transpose) <- names
    # Check the column types
    
    
    df_new <-df[,-c(1)]
    
    
    df_new<-cbind(df$SEVERITY,df_new[, (names(df_new) %in% colnames(transpose)[1:7])])
    
    colnames(df_new)[1] <-'SEVERITY'
    inTrain <- createDataPartition(y=df_new$SEVERITY,p=0.7,list=FALSE)
    
    #Creating the training and cross validation set
    train_set <- df_new[inTrain,]
    cv_set <- df_new[-inTrain,]
    
    
    
    model_rf <- rpart(SEVERITY ~ .,data=train_set)
    #Checking the error on our prediction on the validation set
    cv_prediction_set <- predict(model_rf,cv_set)
    
    rmse <- sqrt(mean((cv_set$SEVERITY - cv_prediction_set) ^ 2))
    paste("The root mean square error is",rmse,sep=" ")
    
    
    log_error <- rmsle(cv_set$SEVERITY,cv_prediction_set)
    paste("The root mean square log error is",log_error,sep=" ")
    
    
    rpart.plot(model_rf,cex = 0.8, digits = 1, 
               box.palette = viridis::viridis(10, option = "D", begin = 0.85, end = 0), 
               shadow.col = "grey65", col = "grey99")
    
  })
}

# call shinyApp and launch it
shinyApp(ui=ui, server=server)
