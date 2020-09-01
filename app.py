from all_data_load import all_data_load

final_df, season_df = all_data_load(2020).load()

final_df.to_csv('NBA_Season_2020.csv',index = False)
season_df.to_csv('NBA_Game_Info.csv',index = False)