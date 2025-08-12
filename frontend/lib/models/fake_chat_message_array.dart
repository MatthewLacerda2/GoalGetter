// Fake chat message array
import 'chat_message.dart';

List<ChatMessage> fakeChatMessages = [
  ChatMessage(
    id: '1',
    message: 'Bishop or knight?',
    sender: ChatMessageSender.user,
  ),
  ChatMessage(
    id: '2',
    message: 'Depends if you are religious or not.',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '3',
    message: 'Bishops value is simply higher, since in many more cases, it was more useful piece',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '4',
    message: 'Bishop covers more squares at once, thus its more valuable.',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '5',
    message: 'Same reason why Queen is worth than both combined, it covers even more squares',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '6',
    message: 'Do i have to activate all my minor pieces before activating my queen?',
    sender: ChatMessageSender.user,
  ),
  ChatMessage(
    id: '7',
    message: 'Yes, as a general rule',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '8',
    message: 'If she is attacked, she has to move away because she is so valuable. So she cannot attack alone',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '9',
    message: 'Its a general rule, so best to follow, but there are exceptions',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '10',
    message: 'Why castling the king? It keeps him constrained',
    sender: ChatMessageSender.user,
  ),
  ChatMessage(
    id: '11',
    message: 'Repeat after me: KING SAFETY IS YOUR #1 PRIORITY',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '12',
    message: 'Mayhem happens in the center, hell be all vulnerable there',
    sender: ChatMessageSender.tutor,
  ),
  ChatMessage(
    id: '13',
    message: 'If you castle, and your opponent didnt, *open up the center*',
    sender: ChatMessageSender.tutor,
  ),
];