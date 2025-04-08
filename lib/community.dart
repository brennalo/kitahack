import 'package:flutter/material.dart';

class Community extends StatefulWidget {
  const Community({super.key});

  @override
  State<Community> createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  // Dummy forum data
  final List<Map<String, dynamic>> forumTopics = [
    {
      'title': 'How to find disability-friendly employers?',
      'author': 'Sarah K.',
      'replies': 24,
      'views': 180,
      'lastActivity': '1 hour ago',
      'content': 'As a person with hearing impairment, I\'m struggling to find companies that truly accommodate disabilities. Any tips on identifying inclusive workplaces?',
    },
    {
      'title': 'Government agency hiring PWDs this month',
      'author': 'Dept. of Social Services',
      'replies': 32,
      'views': 420,
      'lastActivity': '3 hours ago',
      'content': 'Our department has 15 openings specifically for persons with disabilities. Positions include data entry, customer service, and admin roles with full accessibility accommodations.',
    },
    {
      'title': 'Resume tips for visually impaired applicants',
      'author': 'Maria G.',
      'replies': 17,
      'views': 210,
      'lastActivity': '5 hours ago',
      'content': 'How should I format my resume when applying to jobs as someone with low vision? Should I mention my assistive technology skills prominently?',
    },
    {
      'title': 'Tech company seeking neurodiverse candidates',
      'author': 'InclusiveTech Inc.',
      'replies': 8,
      'views': 150,
      'lastActivity': '1 day ago',
      'content': 'We\'re hiring software testers on the autism spectrum. Flexible schedules, sensory-friendly workspace, and tailored support provided. Applications open until 30th!',
    },
    {
      'title': 'Disclosing disability during interviews',
      'author': 'James L.',
      'replies': 29,
      'views': 380,
      'lastActivity': '2 days ago',
      'content': 'When is the right time to disclose my physical disability in the hiring process? I don\'t want it to affect my chances but need workplace adjustments.',
    },
    {
      'title': 'Remote work opportunities for PWDs',
      'author': 'WorkFromHome Solutions',
      'replies': 41,
      'views': 520,
      'lastActivity': '2 days ago',
      'content': 'Curated list of 100% remote positions suitable for various disabilities. Updated weekly with verified accessible job postings.',
    },
    {
      'title': 'Success story: Deaf employee in corporate',
      'author': 'Emma T.',
      'replies': 15,
      'views': 290,
      'lastActivity': '3 days ago',
      'content': 'After 2 years of job hunting, I landed a great role with sign language interpretation support. Sharing my journey to encourage others!',
    },
    {
      'title': 'Accessibility grants for small businesses',
      'author': 'Disability Employment Org',
      'replies': 6,
      'views': 95,
      'lastActivity': '4 days ago',
      'content': 'Funding available for businesses to make workplace adaptations when hiring PWDs. Up to \$10,000 per hire for accessibility modifications.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[600],
        title: const Text('Community Forum'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTopicDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: forumTopics.length,
        itemBuilder: (context, index) {
          final topic = forumTopics[index];
          return _buildTopicCard(topic, context);
        },
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTopicDetail(context, topic),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic['title'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Posted by ${topic['author']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${topic['replies']} replies'),
                      const SizedBox(width: 16),
                      Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${topic['views']} views'),
                    ],
                  ),
                  Text(
                    topic['lastActivity'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTopicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Topic'),
          content: const TextField(
            decoration: InputDecoration(
              hintText: 'Enter your topic title',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New topic created!')),
                );
              },
              child: const Text('Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToTopicDetail(BuildContext context, Map<String, dynamic> topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(topic['title']),
            backgroundColor: Colors.orange[600],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posted by ${topic['author']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  topic['content'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Divider(),
                Text(
                  'Comments (${topic['replies']})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _buildComment('Great topic! I completely agree with your points.', 'User123'),
                _buildComment('Has anyone tried the techniques mentioned here?', 'Helper456'),
                _buildComment('This helped me a lot in my situation.', 'NewMember789'),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Add your comment...',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComment(String text, String author) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              author,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
}