import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/knowledge_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../models/knowledge_model.dart';
import '../../models/user_model.dart';

/// ExpertDashboardScreen is the main screen for solar experts after login
class ExpertDashboardScreen extends StatefulWidget {
  const ExpertDashboardScreen({super.key});

  @override
  _ExpertDashboardScreenState createState() => _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState extends State<ExpertDashboardScreen> {
  int _currentIndex = 0;
  final List<String> _tabs = [
    'Dashboard',
    'Consultations',
    'Knowledge Base',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      knowledgeProvider.fetchArticles(),
      knowledgeProvider.fetchConsultationsByExpert(
        authProvider.user?.uid ?? '',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex]),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Consultations',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Knowledge'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildConsultationsTab();
      case 2:
        return _buildKnowledgeBaseTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final expertConsultations = knowledgeProvider.consultationsByExpert;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(user),

              SizedBox(height: 24),

              // Stats cards
              _buildStatsGrid(knowledgeProvider),

              SizedBox(height: 24),

              // Pending consultations
              Text(
                'Pending Consultations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPendingConsultationsList(
                expertConsultations.where((c) => c.isPending).toList(),
              ),

              SizedBox(height: 24),

              // Recent articles
              Text(
                'Your Recent Articles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildRecentArticlesList(
                knowledgeProvider.articles
                    .where((a) => a.author == user?.name)
                    .toList(),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(UserModel? user) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'E',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'Expert'}!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Solar Energy Expert',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Share your expertise and help customers make informed decisions about solar energy solutions.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(KnowledgeProvider knowledgeProvider) {
    final stats = [
      {
        'title': 'Consultations',
        'value': knowledgeProvider.consultationsByExpert.length.toString(),
        'icon': Icons.support_agent,
        'color': Colors.blue,
      },
      {
        'title': 'Pending',
        'value':
            knowledgeProvider.consultationsByExpert
                .where((c) => c.isPending)
                .length
                .toString(),
        'icon': Icons.pending_actions,
        'color': Colors.orange,
      },
      {
        'title': 'Articles',
        'value':
            knowledgeProvider.articles
                .where(
                  (a) =>
                      a.author == Provider.of<AuthProvider>(context).user?.name,
                )
                .length
                .toString(),
        'icon': Icons.article,
        'color': Colors.green,
      },
      {
        'title': 'Completed',
        'value':
            knowledgeProvider.consultationsByExpert
                .where((c) => c.isCompleted)
                .length
                .toString(),
        'icon': Icons.check_circle,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (stat['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  color: stat['color'] as Color,
                  size: 24,
                ),
              ),
              SizedBox(height: 8),
              Text(
                stat['title'] as String,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingConsultationsList(List<ConsultationModel> consultations) {
    if (consultations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No pending consultations'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: consultations.length > 3 ? 3 : consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(consultation.topic ?? 'Consultation Request'),
            subtitle: Text(
              '${consultation.formattedConsultationDate} • ${consultation.formattedConsultationTime}',
            ),
            trailing: _getStatusBadge(consultation.status),
            onTap: () {
              // View consultation details
              _showConsultationDetailsDialog(consultation);
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentArticlesList(List<KnowledgeBaseModel> articles) {
    if (articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.article, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No articles yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create your first article to share your knowledge',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate to create article
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Create Article'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: articles.length > 3 ? 3 : articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Container(
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(article.mainImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(article.title),
            subtitle: Text(article.categoryName),
            trailing:
                article.featured
                    ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Text(
                        'FEATURED',
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    : null,
            onTap: () {
              // View article details
            },
          ),
        );
      },
    );
  }

  Widget _buildConsultationsTab() {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);

    if (knowledgeProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildConsultationsList(
                  knowledgeProvider.consultationsByExpert
                      .where((c) => c.isPending)
                      .toList(),
                ),
                _buildConsultationsList(
                  knowledgeProvider.consultationsByExpert
                      .where((c) => c.isConfirmed)
                      .toList(),
                ),
                _buildConsultationsList(
                  knowledgeProvider.consultationsByExpert
                      .where((c) => c.isCompleted)
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList(List<ConsultationModel> consultations) {
    if (consultations.isEmpty) {
      return Center(child: Text('No consultations found'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(consultation.topic ?? 'Consultation Request'),
                subtitle: Text(
                  '${consultation.formattedConsultationDate} • ${consultation.duration}',
                ),
                trailing: _getStatusBadge(consultation.status),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (consultation.userQuestions != null) ...[
                      Text(
                        'Questions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        consultation.userQuestions!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (consultation.notes != null) ...[
                      Text(
                        'Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        consultation.notes!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (consultation.expertResponse != null) ...[
                      Text(
                        'Your Response:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        consultation.expertResponse!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  if (consultation.isPending)
                    TextButton(
                      onPressed: () {
                        // Confirm consultation
                        _confirmConsultation(consultation);
                      },
                      child: Text('Confirm'),
                    ),
                  if (consultation.isPending || consultation.isConfirmed)
                    TextButton(
                      onPressed: () {
                        // Add response
                        _showAddResponseDialog(consultation);
                      },
                      child: Text('Add Response'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmConsultation(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Consultation'),
            content: Text(
              'Are you sure you want to confirm this consultation?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final knowledgeProvider = Provider.of<KnowledgeProvider>(
                    context,
                    listen: false,
                  );
                  await knowledgeProvider.updateConsultationStatus(
                    consultation.id,
                    'confirmed',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Consultation confirmed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showAddResponseDialog(ConsultationModel consultation) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Response'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add your response to the consultation:'),
                SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Your response...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (responseController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter a response'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);

                  final knowledgeProvider = Provider.of<KnowledgeProvider>(
                    context,
                    listen: false,
                  );
                  await knowledgeProvider.addExpertResponse(
                    consultation.id,
                    responseController.text,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Response added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Submit'),
              ),
            ],
          ),
    );
  }

  void _showConsultationDetailsDialog(ConsultationModel consultation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Consultation Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (consultation.topic != null)
                    _buildDetailItem('Topic', consultation.topic!),
                  _buildDetailItem(
                    'Date',
                    consultation.formattedConsultationDate,
                  ),
                  _buildDetailItem(
                    'Time',
                    consultation.formattedConsultationTime,
                  ),
                  _buildDetailItem('Duration', consultation.duration),
                  _buildDetailItem('Status', consultation.status),
                  if (consultation.userQuestions != null)
                    _buildDetailItem('Questions', consultation.userQuestions!),
                  if (consultation.notes != null)
                    _buildDetailItem('Notes', consultation.notes!),
                  if (consultation.expertResponse != null)
                    _buildDetailItem(
                      'Your Response',
                      consultation.expertResponse!,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              if (consultation.isPending)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmConsultation(consultation);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Confirm'),
                ),
              if (consultation.isPending || consultation.isConfirmed)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddResponseDialog(consultation);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text('Add Response'),
                ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseTab() {
    final knowledgeProvider = Provider.of<KnowledgeProvider>(context);

    if (knowledgeProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: 'All Articles'), Tab(text: 'My Articles')],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Create new article
                  },
                  icon: Icon(Icons.add),
                  label: Text('New'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildArticlesList(knowledgeProvider.articles),
                _buildArticlesList(
                  knowledgeProvider.articles
                      .where(
                        (a) =>
                            a.author ==
                            Provider.of<AuthProvider>(context).user?.name,
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlesList(List<KnowledgeBaseModel> articles) {
    if (articles.isEmpty) {
      return Center(child: Text('No articles found'));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  article.mainImageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.image_not_supported, size: 40),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            article.categoryName,
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          article.formattedCreatedAt,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 8),

                    // Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Excerpt
                    Text(
                      article.excerpt,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 16),

                    // Tags and actions
                    Row(
                      children: [
                        if (article.tags.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  article.tags.take(3).map((tag) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        if (article.author ==
                            Provider.of<AuthProvider>(context).user?.name)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  // Edit article
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // Delete article
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  // Profile picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(0.1),
                      image:
                          user?.profilePicture != null
                              ? DecorationImage(
                                image: NetworkImage(user!.profilePicture!),
                                fit: BoxFit.cover,
                              )
                              : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child:
                        user?.profilePicture == null
                            ? Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'E',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            )
                            : null,
                  ),

                  SizedBox(height: 16),

                  // User name
                  Text(
                    user?.name ?? 'Expert',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 4),

                  // User email
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),

                  SizedBox(height: 8),

                  // User type badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Solar Energy Expert',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Edit profile button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to edit profile
                    },
                    icon: Icon(Icons.edit),
                    label: Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Expertise section
            Text(
              'Expertise',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            // Expertise card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specialization',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    user?.specialization ?? 'Solar Energy Systems',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Experience',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '5+ years in solar energy consulting',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Skills',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'Solar Panel Design',
                          'Energy Efficiency',
                          'System Sizing',
                          'Technical Consulting',
                          'Renewable Energy',
                        ].map((skill) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Account section
            Text(
              'Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 16),

            // Account menu items
            _buildProfileMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {
                // Navigate to notifications
              },
            ),

            _buildProfileMenuItem(
              icon: Icons.lock,
              title: 'Security',
              subtitle: 'Change password and security settings',
              onTap: () {
                // Navigate to security settings
              },
            ),

            _buildProfileMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              subtitle: 'Get help with your account',
              onTap: () {
                // Navigate to help and support
              },
            ),

            SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.signOut();
                  if (mounted) {
                    AppRoutes.navigateAndRemoveUntil(
                      context,
                      AppRoutes.welcome,
                    );
                  }
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
