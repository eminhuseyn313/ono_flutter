import '../models/radio.dart';
import 'radio_gateway.dart';

/// Mock implementation of [RadioGateway] with seeded data for 4 role models.
class MockRadioGateway implements RadioGateway {
  final Set<String> _listenedIds = {};

  late final List<RadioPlaylist> _playlists = _buildPlaylists();

  List<RadioPlaylist> _buildPlaylists() {
    return [
      _buildMarcusAurelius(),
      _buildDavidGoggins(),
      _buildElonMusk(),
      _buildCristianoRonaldo(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Marcus Aurelius
  // ---------------------------------------------------------------------------
  RadioPlaylist _buildMarcusAurelius() {
    const rm = 'rm_marcus_aurelius';
    return RadioPlaylist(
      roleModelId: rm,
      roleModelName: 'Marcus Aurelius',
      roleModelEmoji: '\u{1F3DB}',
      channels: {
        RadioChannel.theirWords: [
          const RadioItem(
            id: '${rm}_w1',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'The Daily Stoic Podcast',
            subtitle: 'Ryan Holiday',
            description:
                'Daily meditations on Stoic philosophy applied to modern life.',
            externalUrl: 'https://open.spotify.com/show/7fY99FB2O0jRmCb0sWpRsP',
            platform: RadioPlatform.spotify,
            duration: Duration(minutes: 12),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w2',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Stoicism for Modern Life',
            subtitle: 'Massimo Pigliucci',
            description:
                'How ancient Stoic teachings translate to modern challenges.',
            externalUrl:
                'https://podcasts.apple.com/us/podcast/stoicism-for-modern-life/id1489122785',
            platform: RadioPlatform.applePodcasts,
            duration: Duration(minutes: 35),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w3',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Ryan Holiday - Obstacle is the Way Talk',
            subtitle: 'Google Talks',
            description:
                'Ryan Holiday discusses turning obstacles into advantages.',
            externalUrl: 'https://www.youtube.com/watch?v=Qd2xOIhS7VE',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 48),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w4',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Marcus Aurelius - Meditations Audiobook',
            subtitle: 'Full Unabridged',
            description:
                'The classic Meditations read in a calm, reflective tone.',
            externalUrl: 'https://www.youtube.com/watch?v=d5E2AQKuCyU',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 4, minutes: 30),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w5',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'The Philosophy of Stoicism - TED-Ed',
            subtitle: 'Massimo Pigliucci',
            description: 'A concise animated overview of Stoic philosophy.',
            externalUrl: 'https://www.youtube.com/watch?v=R9OCA6UFE-0',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 5),
            isMorning: true,
            isEvening: false,
          ),
        ],
        RadioChannel.soundtrack: [
          const RadioItem(
            id: '${rm}_s1',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Classical Focus Playlist',
            subtitle: 'Deep concentration with classical masters',
            description:
                'Bach, Vivaldi, and Mozart for deep focused work sessions.',
            externalUrl: 'spotify:playlist:37i9dQZF1DWZeKCadgRdKQ',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s2',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Meditation Ambient',
            subtitle: 'Calm ambient sounds for reflection',
            description: 'Gentle ambient textures for meditation and journaling.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX3Ogo9pFvBkY',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 30),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s3',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Stoic Calm',
            subtitle: 'Piano & strings for tranquility',
            description:
                'Soft piano and string arrangements for inner stillness.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX4sWSpwq3LiO',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s4',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Neoclassical Morning',
            subtitle: 'Nils Frahm, Ólafur Arnalds & more',
            description:
                'Modern classical pieces to start the day with clarity.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX5trt9i14X7j',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 45),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s5',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Ancient Rome Soundscape',
            subtitle: 'Historical ambient atmospheres',
            description:
                'Immersive soundscapes evoking the atmosphere of ancient Rome.',
            externalUrl: 'https://www.youtube.com/watch?v=JX5r1tPVmRE',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 3),
            isMorning: false,
            isEvening: true,
          ),
        ],
        RadioChannel.library: [
          const RadioItem(
            id: '${rm}_l1',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Meditations',
            subtitle: 'Marcus Aurelius',
            description:
                'Personal writings of the Roman Emperor on Stoic philosophy.',
            externalUrl:
                'https://www.amazon.com/Meditations-New-Translation-Marcus-Aurelius/dp/0812968255',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l2',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Letters from a Stoic',
            subtitle: 'Seneca',
            description:
                'Seneca\'s timeless letters on virtue, friendship, and mortality.',
            externalUrl:
                'https://www.amazon.com/Letters-Stoic-Penguin-Classics-Seneca/dp/0140442103',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l3',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'The Obstacle Is the Way',
            subtitle: 'Ryan Holiday',
            description:
                'The ancient art of turning trials into triumph.',
            externalUrl:
                'https://www.amazon.com/Obstacle-Way-Timeless-Turning-Triumph/dp/1591846358',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l4',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'A Guide to the Good Life',
            subtitle: 'William B. Irvine',
            description:
                'The ancient art of Stoic joy applied to modern living.',
            externalUrl:
                'https://www.amazon.com/Guide-Good-Life-Ancient-Stoic/dp/0195374614',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l5',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'The Daily Stoic',
            subtitle: 'Ryan Holiday & Stephen Hanselman',
            description:
                '366 meditations on wisdom, perseverance, and the art of living.',
            externalUrl:
                'https://www.amazon.com/Daily-Stoic-Meditations-Wisdom-Perseverance/dp/0735211736',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: true,
          ),
        ],
      },
    );
  }

  // ---------------------------------------------------------------------------
  // David Goggins
  // ---------------------------------------------------------------------------
  RadioPlaylist _buildDavidGoggins() {
    const rm = 'rm_david_goggins';
    return RadioPlaylist(
      roleModelId: rm,
      roleModelName: 'David Goggins',
      roleModelEmoji: '\u{1F525}',
      channels: {
        RadioChannel.theirWords: [
          const RadioItem(
            id: '${rm}_w1',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Can\'t Hurt Me Audiobook Clips',
            subtitle: 'David Goggins',
            description:
                'Key excerpts from the best-selling book on mental toughness.',
            externalUrl: 'https://www.youtube.com/watch?v=5tSTk1083VY',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 22),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w2',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Joe Rogan Experience #1080',
            subtitle: 'Joe Rogan & David Goggins',
            description:
                'The iconic episode where Goggins shares his full story.',
            externalUrl:
                'https://open.spotify.com/episode/6PNJzPMXVnGuwRefMNFJlg',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2, minutes: 55),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w3',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Impact Theory Interview',
            subtitle: 'Tom Bilyeu & David Goggins',
            description: 'How to build an unbreakable mind.',
            externalUrl: 'https://www.youtube.com/watch?v=78I9dTB36CY',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 1, minutes: 10),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w4',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Goggins on Modern Wisdom',
            subtitle: 'Chris Williamson',
            description: 'Suffering builds character and resilience.',
            externalUrl: 'https://www.youtube.com/watch?v=nOFnEyCjPAI',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 1, minutes: 45),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w5',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Andrew Huberman x Goggins',
            subtitle: 'Huberman Lab',
            description:
                'The neuroscience behind willpower and Goggins\' mental edge.',
            externalUrl:
                'https://open.spotify.com/episode/3RrVuBZPkKBo4eqbgnL3Vk',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2, minutes: 30),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w6',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Navy SEAL Motivation Speech',
            subtitle: 'David Goggins Compilation',
            description: 'A compilation of Goggins\' most powerful speeches.',
            externalUrl: 'https://www.youtube.com/watch?v=TLKxdTmk-zc',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 15),
            isMorning: true,
            isEvening: false,
          ),
        ],
        RadioChannel.soundtrack: [
          const RadioItem(
            id: '${rm}_s1',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Beast Mode Workout',
            subtitle: 'High-intensity training mix',
            description:
                'Aggressive beats for pushing through physical limits.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX76Wlfdnj7AP',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 30),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s2',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'David Goggins Running Mix',
            subtitle: 'Endurance running playlist',
            description:
                'Steady tempo tracks for long-distance running sessions.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX35X4JNyBWtb',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s3',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'No Excuses Playlist',
            subtitle: 'Motivational hip-hop & rap',
            description: 'Hard-hitting tracks that fuel the no-quit mindset.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX4eRPd9frC1m',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 15),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s4',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Recovery & Reflection',
            subtitle: 'Post-workout wind-down',
            description: 'Calm beats for stretching and evening recovery.',
            externalUrl: 'spotify:playlist:37i9dQZF1DWUzFXarNiofw',
            platform: RadioPlatform.spotify,
            duration: Duration(minutes: 45),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s5',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: '4 AM Wake-Up Call',
            subtitle: 'Pre-dawn intensity',
            description:
                'Dark, driving beats for early morning training sessions.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX3rxVfibe1L0',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1),
            isMorning: true,
            isEvening: false,
          ),
        ],
        RadioChannel.library: [
          const RadioItem(
            id: '${rm}_l1',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Can\'t Hurt Me',
            subtitle: 'David Goggins',
            description:
                'Master your mind and defy the odds. The book that started it all.',
            externalUrl:
                'https://www.amazon.com/Cant-Hurt-Me-Master-Your/dp/1544512287',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l2',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Never Finished',
            subtitle: 'David Goggins',
            description:
                'Unshackle your mind and win the war within. The follow-up.',
            externalUrl:
                'https://www.amazon.com/Never-Finished-Unshackle-Your-Within/dp/1544534086',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l3',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Extreme Ownership',
            subtitle: 'Jocko Willink & Leif Babin',
            description:
                'How U.S. Navy SEALs lead and win through radical accountability.',
            externalUrl:
                'https://www.amazon.com/Extreme-Ownership-U-S-Navy-SEALs/dp/1250183863',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l4',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Living with a SEAL',
            subtitle: 'Jesse Itzler',
            description:
                'What happens when you invite David Goggins to live in your house.',
            externalUrl:
                'https://www.amazon.com/Living-SEAL-Training-Toughest-Planet/dp/1455534684',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l5',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Discipline Equals Freedom',
            subtitle: 'Jocko Willink',
            description: 'A field manual for discipline, focus, and willpower.',
            externalUrl:
                'https://www.amazon.com/Discipline-Equals-Freedom-Field-Manual/dp/1250156947',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
        ],
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Elon Musk
  // ---------------------------------------------------------------------------
  RadioPlaylist _buildElonMusk() {
    const rm = 'rm_elon_musk';
    return RadioPlaylist(
      roleModelId: rm,
      roleModelName: 'Elon Musk',
      roleModelEmoji: '\u{1F680}',
      channels: {
        RadioChannel.theirWords: [
          const RadioItem(
            id: '${rm}_w1',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Lex Fridman Podcast #252',
            subtitle: 'Lex Fridman & Elon Musk',
            description:
                'Deep discussion on AI, Mars, manufacturing, and first principles.',
            externalUrl:
                'https://open.spotify.com/episode/4PFpGJCWB1hYBcFsBKXpKG',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2, minutes: 30),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w2',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'TED Talk: The Future of Energy',
            subtitle: 'Elon Musk at TED',
            description:
                'Musk\'s vision for sustainable energy and transportation.',
            externalUrl: 'https://www.youtube.com/watch?v=IgKWPdJWuBQ',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 21),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w3',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'SpaceX Starship Update',
            subtitle: 'SpaceX Official',
            description:
                'Technical deep-dive into the Starship program and Mars plans.',
            externalUrl: 'https://www.youtube.com/watch?v=3N7L8Xhkzqo',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 1, minutes: 5),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w4',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Joe Rogan Experience #1169',
            subtitle: 'Joe Rogan & Elon Musk',
            description: 'The viral Rogan episode covering AI, tunnels, and more.',
            externalUrl:
                'https://open.spotify.com/episode/2aB2swgyXqbFA06AxPlFmr',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2, minutes: 37),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w5',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'USC Commencement Speech',
            subtitle: 'Elon Musk',
            description: 'Musk\'s advice on thinking big and working hard.',
            externalUrl: 'https://www.youtube.com/watch?v=e7Qh-vwpYH8',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 18),
            isMorning: true,
            isEvening: false,
          ),
        ],
        RadioChannel.soundtrack: [
          const RadioItem(
            id: '${rm}_s1',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Deep Work Electronic',
            subtitle: 'Minimal techno for focus',
            description:
                'Stripped-back electronic beats for engineering deep work.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX5trt9i14X7j',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2, minutes: 30),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s2',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Space Ambient',
            subtitle: 'Cosmic soundscapes',
            description:
                'Vast ambient textures inspired by interstellar exploration.',
            externalUrl: 'spotify:playlist:37i9dQZF1DWVFJtzvDHN4L',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 3),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s3',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Techno Focus',
            subtitle: 'Driving rhythms for productivity',
            description:
                'High-energy techno for marathon coding and design sessions.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX6J5NfMJS675',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 45),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s4',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Synthwave Retro Future',
            subtitle: 'Neon-lit productivity',
            description: 'Retro-futuristic synths for visionary thinking.',
            externalUrl: 'spotify:playlist:37i9dQZF1DXdLEN7aqioXM',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2),
            isMorning: true,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s5',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Mars Colony Ambient',
            subtitle: 'Futuristic atmospheric',
            description: 'Sci-fi ambient for late-night brainstorming.',
            externalUrl: 'https://www.youtube.com/watch?v=cMWkuP5QyPo',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 2),
            isMorning: false,
            isEvening: true,
          ),
        ],
        RadioChannel.library: [
          const RadioItem(
            id: '${rm}_l1',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'The Hitchhiker\'s Guide to the Galaxy',
            subtitle: 'Douglas Adams',
            description:
                'Musk\'s favorite novel; a comedic journey across the universe.',
            externalUrl:
                'https://www.amazon.com/Hitchhikers-Guide-Galaxy-Douglas-Adams/dp/0345391802',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l2',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Structures: Or Why Things Don\'t Fall Down',
            subtitle: 'J.E. Gordon',
            description:
                'Engineering fundamentals Musk credits for SpaceX insight.',
            externalUrl:
                'https://www.amazon.com/Structures-Things-Dont-Fall-Down/dp/0306812835',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l3',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Zero to One',
            subtitle: 'Peter Thiel',
            description:
                'Notes on startups, monopoly thinking, and building the future.',
            externalUrl:
                'https://www.amazon.com/Zero-One-Notes-Startups-Future/dp/0804139296',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l4',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Ignition! An Informal History of Liquid Rocket Propellants',
            subtitle: 'John Drury Clark',
            description:
                'The wild history of rocket fuel science Musk loves to reference.',
            externalUrl:
                'https://www.amazon.com/Ignition-Informal-History-Liquid-Propellants/dp/0813595835',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l5',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'The Foundation Trilogy',
            subtitle: 'Isaac Asimov',
            description:
                'Sci-fi epic about saving civilization that inspired Musk.',
            externalUrl:
                'https://www.amazon.com/Foundation-Isaac-Asimov/dp/0553293354',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l6',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Superintelligence',
            subtitle: 'Nick Bostrom',
            description:
                'Paths, dangers, and strategies around artificial superintelligence.',
            externalUrl:
                'https://www.amazon.com/Superintelligence-Dangers-Strategies-Nick-Bostrom/dp/0198739834',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
        ],
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Cristiano Ronaldo
  // ---------------------------------------------------------------------------
  RadioPlaylist _buildCristianoRonaldo() {
    const rm = 'rm_cristiano_ronaldo';
    return RadioPlaylist(
      roleModelId: rm,
      roleModelName: 'Cristiano Ronaldo',
      roleModelEmoji: '\u{26BD}',
      channels: {
        RadioChannel.theirWords: [
          const RadioItem(
            id: '${rm}_w1',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'CR7 Interview - Piers Morgan',
            subtitle: 'Piers Morgan Uncensored',
            description:
                'The explosive interview where Ronaldo opens up about his career.',
            externalUrl: 'https://www.youtube.com/watch?v=yjNFv8sPLHs',
            platform: RadioPlatform.youtube,
            duration: Duration(hours: 1, minutes: 30),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w2',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Champions League Press Conferences',
            subtitle: 'UEFA Official',
            description:
                'Ronaldo\'s best press conference moments and insights.',
            externalUrl: 'https://www.youtube.com/watch?v=VCdMH0GK7Xs',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 25),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w3',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Ronaldo Documentary Clips',
            subtitle: 'Universal Pictures',
            description:
                'Behind the scenes of the 2015 documentary on Ronaldo\'s life.',
            externalUrl: 'https://www.youtube.com/watch?v=qxFRD4vgmmc',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 45),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_w4',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'Rio Ferdinand Interviews CR7',
            subtitle: 'FIVE YouTube',
            description: 'Ronaldo talks legacy, rivalry, and winning mentality.',
            externalUrl: 'https://www.youtube.com/watch?v=KdNfLySVbvA',
            platform: RadioPlatform.youtube,
            duration: Duration(minutes: 38),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_w5',
            roleModelId: rm,
            channel: RadioChannel.theirWords,
            title: 'I Am Georgina - Podcast Clips',
            subtitle: 'Netflix Audio',
            description:
                'Insights into Ronaldo\'s personal life and family values.',
            externalUrl:
                'https://open.spotify.com/episode/7rWR2ArCvRYCxV7lNqU3Oj',
            platform: RadioPlatform.spotify,
            duration: Duration(minutes: 55),
            isMorning: false,
            isEvening: true,
          ),
        ],
        RadioChannel.soundtrack: [
          const RadioItem(
            id: '${rm}_s1',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Gym Motivation Mix',
            subtitle: 'High-energy workout beats',
            description:
                'Pump-up tracks for training like a world-class athlete.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX70RN3TfnE5v',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 30),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s2',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Portuguese Vibes',
            subtitle: 'Music from Portugal',
            description:
                'From Fado to modern Portuguese pop celebrating Ronaldo\'s roots.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX2vmJGQ5JaKM',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 2),
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_s3',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Victory Anthems',
            subtitle: 'Stadium celebration playlist',
            description:
                'Anthems that play when champions lift the trophy.',
            externalUrl: 'spotify:playlist:37i9dQZF1DWYs2pvJFBaRQ',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s4',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Pre-Match Focus',
            subtitle: 'Mental preparation playlist',
            description: 'Intense focus tracks for mental game preparation.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX4o1oenSJRJd',
            platform: RadioPlatform.spotify,
            duration: Duration(minutes: 45),
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_s5',
            roleModelId: rm,
            channel: RadioChannel.soundtrack,
            title: 'Recovery Chill',
            subtitle: 'Post-match wind-down',
            description: 'Smooth R&B and chill tracks for recovery evenings.',
            externalUrl: 'spotify:playlist:37i9dQZF1DX2TRYkJECvfC',
            platform: RadioPlatform.spotify,
            duration: Duration(hours: 1, minutes: 15),
            isMorning: false,
            isEvening: true,
          ),
        ],
        RadioChannel.library: [
          const RadioItem(
            id: '${rm}_l1',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Ronaldo: The Obsession for Perfection',
            subtitle: 'Luca Caioli',
            description:
                'The definitive biography of Cristiano Ronaldo\'s relentless pursuit.',
            externalUrl:
                'https://www.amazon.com/Ronaldo-Obsession-Perfection-Luca-Caioli/dp/1906850658',
            platform: RadioPlatform.amazon,
            isMorning: false,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l2',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'The Mamba Mentality',
            subtitle: 'Kobe Bryant',
            description:
                'Kobe\'s mindset book — the competitive philosophy Ronaldo embodies.',
            externalUrl:
                'https://www.amazon.com/Mamba-Mentality-How-Play/dp/0374201234',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l3',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Relentless',
            subtitle: 'Tim S. Grover',
            description:
                'From good to great to unstoppable — the mindset of champions.',
            externalUrl:
                'https://www.amazon.com/Relentless-Unstoppable-Tim-S-Grover/dp/1476714207',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
          const RadioItem(
            id: '${rm}_l4',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Legacy',
            subtitle: 'James Kerr',
            description:
                'Leadership lessons from the All Blacks, the greatest team ever.',
            externalUrl:
                'https://www.amazon.com/Legacy-James-Kerr/dp/1472103536',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: true,
          ),
          const RadioItem(
            id: '${rm}_l5',
            roleModelId: rm,
            channel: RadioChannel.library,
            title: 'Atomic Habits',
            subtitle: 'James Clear',
            description:
                'The small habits system behind elite athletic performance.',
            externalUrl:
                'https://www.amazon.com/Atomic-Habits-Proven-Build-Break/dp/0735211299',
            platform: RadioPlatform.amazon,
            isMorning: true,
            isEvening: false,
          ),
        ],
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Gateway Implementation
  // ---------------------------------------------------------------------------

  @override
  Future<RadioPlaylist> loadPlaylist(String roleModelId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _playlists.firstWhere(
      (p) => p.roleModelId == roleModelId,
      orElse: () => throw Exception('Playlist not found for $roleModelId'),
    );
  }

  @override
  Future<List<RadioPlaylist>> loadAllPlaylists() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_playlists);
  }

  @override
  Future<List<RadioItem>> loadFeaturedItems(String timeOfDay) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final isMorningTime = timeOfDay == 'morning';
    final featured = <RadioItem>[];
    for (final playlist in _playlists) {
      for (final items in playlist.channels.values) {
        for (final item in items) {
          if (isMorningTime && item.isMorning) {
            featured.add(item);
          } else if (!isMorningTime && item.isEvening) {
            featured.add(item);
          }
        }
      }
    }
    // Shuffle and take top 6 for featured section.
    featured.shuffle();
    return featured.take(6).toList();
  }

  @override
  Future<void> markAsListened(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _listenedIds.add(itemId);
  }

  @override
  Future<Set<String>> getListenedIds() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Set.unmodifiable(_listenedIds);
  }
}
