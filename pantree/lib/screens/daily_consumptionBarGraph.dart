import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pantree/models/local_user_manager.dart';
import 'package:pantree/models/user_profile.dart';
import 'package:pantree/services/user_consumption_service.dart';
import 'package:pantree/models/user_consumption_model.dart';

class DailyConsumptionScreenGraph extends StatefulWidget {
  const DailyConsumptionScreenGraph({Key? key}) : super(key: key);

  @override
  _DailyConsumptionScreenGraphState createState() =>
      _DailyConsumptionScreenGraphState();
}

class _DailyConsumptionScreenGraphState
    extends State<DailyConsumptionScreenGraph> {
  // attributes needed for this class
  UserConsumption? currentConsumption;
  UserProfile? userProfile;
  double? userCalorieGoal;
  double? userProteinGoal;
  double? userCarbGoal;
  double? userFatGoal;
  List<NutrientBarData> nutrientDataList = [];

  @override
  void initState() {
    super.initState();
    fetchCurrentConsumption();
    fetchUserProfile();
  }

  // WHERE WE FETCH THE USER CURRENT CONSUMPTION
  Future<void> fetchCurrentConsumption() async {
    String userID = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      DateTime currentDate = DateTime.now();
      var consumptionData = await ConsumptionService.instance
          .getUserConsumptionData(userID, currentDate);
      print('Fetched Data: $consumptionData');
      setState(() {
        currentConsumption = consumptionData;
      });
    } catch (e) {
      print('Error fetching consumption data: $e');
    }
  }

  // WHERE WE FETCH THE PROFILE AND ATTRIBUTES
  void fetchUserProfile() async {
    final localUserManager = LocalUserManager();
    userProfile = localUserManager.getCachedUser();

    if (userProfile == null) {
      String userID = FirebaseAuth.instance.currentUser?.uid ?? '';
      await localUserManager.fetchAndUpdateUser(userID);
      userProfile = localUserManager.getCachedUser();
    }
    if (userProfile != null) {
      userCalorieGoal =
          localUserManager.getUserAttribute('Calories') as double?;
      userProteinGoal = localUserManager.getUserAttribute('Protein') as double?;
      userCarbGoal = localUserManager.getUserAttribute('Carbs') as double?;
      userFatGoal = localUserManager.getUserAttribute('Fat') as double?;
    }
    setState(() {});
  }

  List<NutrientBarData> generateNutrientData() {
    List<NutrientBarData> dataList = [];

    if (currentConsumption != null && userProfile != null) {
      // Extract the nutrient values from currentConsumption and userProfile
      double currentCalories = currentConsumption!.totalCalories;
      double currentProteins = currentConsumption!.totalProteins;
      double currentCarbs = currentConsumption!.totalCarbs;
      double currentFats = currentConsumption!.totalFats;

      double goalCalories = userCalorieGoal ?? 0;
      double goalProteins = userProteinGoal ?? 0;
      double goalCarbs = userCarbGoal ?? 0;
      double goalFats = userFatGoal ?? 0;

      // Create NutrientBarData instances for each nutrient
      dataList.add(NutrientBarData('Calories', currentCalories, goalCalories));
      dataList.add(NutrientBarData('Proteins', currentProteins, goalProteins));
      dataList.add(NutrientBarData('Carbs', currentCarbs, goalCarbs));
      dataList.add(NutrientBarData('Fats', currentFats, goalFats));
    }

    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    nutrientDataList = generateNutrientData();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Consumption',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
                height: 340,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).appBarTheme.backgroundColor),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: Text(
                            'Daily Overview',
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.fontSize ??
                                  16,
                              fontWeight: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.fontWeight,
                            ),
                          ),
                        )
                        // here is where you need to add arrow to navigate to other page
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          height: 270,
                          width: 345,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color:
                                Theme.of(context).appBarTheme.backgroundColor ??
                                    Colors.black ??
                                    Colors.white,
                          ),
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              return NutrientBarChart(
                                  dataList: nutrientDataList);
                            }, // Removed Expanded),
                          ),
                        ))
                  ],
                )),

            //WHERE NUTRITIONAL SUMMARY BEGINS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 25, 0, 4),
                  child: Text(
                    'Nutritional Summary',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 0, 0, 10),
                  child: Text(
                    'Overview of your daily consumption.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildNutrientCard('Calories',
                        '${currentConsumption?.totalCalories.toStringAsFixed(0)} kcal'),
                    buildNutrientCard('Proteins',
                        '${currentConsumption?.totalProteins.toStringAsFixed(0)} g'),
                    buildNutrientCard('Carbs',
                        '${currentConsumption?.totalCarbs.toStringAsFixed(0)} g'),
                    buildNutrientCard('Fats',
                        '${currentConsumption?.totalFats.toStringAsFixed(0)} g'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// widget for each nutrient card such as calories, and others....
  Widget buildNutrientCard(String nutrient, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor ??
              Colors.black ??
              Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 2,
              color: Color(0xFFE0E3E7),
              offset: Offset(0, .2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nutrient,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NutrientBarData {
  final String nutrient;
  final double consumption;
  final double goal;

  NutrientBarData(this.nutrient, this.consumption, this.goal);
}

class NutrientBarChart extends StatefulWidget {
  final List<NutrientBarData> dataList;

  NutrientBarChart({Key? key, required this.dataList}) : super(key: key);

  @override
  _NutrientBarChartState createState() => _NutrientBarChartState();
}

class _NutrientBarChartState extends State<NutrientBarChart> {
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: const Color(0xff37434d),
            width: 1,
          ),
        ),
        barGroups: widget.dataList
            .asMap()
            .map((index, data) {
              return MapEntry(
                  index,
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.consumption,
                        color: Colors.blue,
                        width: 16,
                      ),
                      BarChartRodData(
                        toY: data.goal,
                        color: Colors.green,
                        width: 16,
                      ),
                    ],
                  ));
            })
            .values
            .toList(),
      ),
    );
  }
}
