Declare @cmd varchar(8000)
Declare @dbs varchar(3000)
Declare @dbname varchar(32)

Set @dbs = 'ABECU32,AddisonAve32,AEA,AFS,AltaOne,AmericaFirst32,AmericanAirlines,ArizonaStateCU,ArmyAviation,Baxter,BayFederal,Bellco32,Bethpage40,BlackHawk,Boeing4,Chetco,CityCounty32,ColonialRLC,Columbia32,ConfigurationManagement,ConstructionLoanCompany,ConsumersCU,CornellFingerLake,CUAnswers,CUCompanies,CUMA,CUMembers,CUNational,CUWest,DenverPublicSchools,Dexma01,DexmaRLC,DexmaSites,Dupont,EDCO,ENT,FirstAmerican,FirstAtlantic,FirstFarmers,FirstFuture32,FirstTech,GeorgiaTelco,GTE32,HiwayCU,HomeownersMtg,HotfixSite,Hutchinson,IBMSoutheast,Kern32,Kinecta,Lockheed32,McDillAFB,MembersMortgage,Merchants,Meriwest32,Merrimack,MidMinnesota,MidwestFinancial,MidwestLoan32,MissionFed40,NASA,Numerica,NYMunicipal,OrangeCounty32,ORNL,OTCCU,PADemoDU,PADemoLP,PAPrototype_DataMart,PAReporting,PASCAdmin,Patelco32,PATest,PATrain,PeoplesTrust,PremierAmerica,PSECU3,Purdue,PWBDefaultClient,RBC,Redwood,Rivermark,RLC,Safe32,SDCCU32,sdtConditionsManagement,SecurityServices,SFFCU,SouthCarolina32,SpaceCoast,SPI10,spiQA_HNC,spiQAbase,SPToolTest,StarOne,Suncoast32,TLEDemo,TLETrain,Tower32,Travis40,UpgradeTest,Vandenberg32,Verity,Visions,VyStar,Weokie,WesCom,Weyerhaeuser,WrightPatt32'


declare dbname cursor for 
	select * from [dbamaint].[dbo].[udf_split](@dbs,',')

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 

--print @dbname

select @cmd =		' USE [' + @dbname + ']' + char(13) +
					' update site_data_elements set sde_elementValue = @@servername where sde_elementName = ''sc_dbserver''' + char(13)

print(@cmd)
--exec(@cmd)
fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname 
