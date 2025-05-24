import 'package:flutter/material.dart';
import 'package:kerala_tech_reach/models/job.dart';
import 'package:share_plus/share_plus.dart';
import 'job_detail_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/job_list_provider.dart';

class _SavedJob {
  final Job job;
  _SavedJob(this.job);
  Map<String, dynamic> toJson() => job.toJson();
  static _SavedJob fromJson(Map<String, dynamic> json) => _SavedJob(Job.fromJson(json));
}

class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JobListProvider()..fetchJobs(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Jobs')),
        body: Consumer<JobListProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter by role/title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: provider.setRoleFilter,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = provider.filteredJobs[index];
                      final isSaved = provider.savedJobs.contains(job);
                      return ListTile(
                        title: Text(job.title),
                        subtitle: Text(job.description),
                        trailing: IconButton(
                          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                          onPressed: () {
                            isSaved ? provider.removeSavedJob(job) : provider.saveJob(job);
                          },
                        ),
                        onTap: () => _onJobTap(context, job),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onJobTap(BuildContext context, Job job) async {
    int newCounter = Provider.of<JobListProvider>(context, listen: false).adCounter + 1;
    if (newCounter % 5 == 0) {
      _showRewardedAd(context);
      newCounter = 0;
    }
    Provider.of<JobListProvider>(context, listen: false).updateAdCounter(newCounter);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailScreen(jobId: job.id),
      ),
    );
  }

  void _showRewardedAd(BuildContext context) {
    RewardedAd? rewardedAd = Provider.of<JobListProvider>(context, listen: false).rewardedAd;
    if (rewardedAd != null) {
      rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          Provider.of<JobListProvider>(context, listen: false).initRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          Provider.of<JobListProvider>(context, listen: false).initRewardedAd();
        },
      );
      rewardedAd.show(onUserEarnedReward: (ad, reward) {});
      Provider.of<JobListProvider>(context, listen: false).updateRewardedAd(null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad not ready.')));
      Provider.of<JobListProvider>(context, listen: false).initRewardedAd();
    }
  }

  void _shareJob(BuildContext context, Job job) {
    Share.share('Check out this job: ${job.title}\n${job.description}');
  }
} 