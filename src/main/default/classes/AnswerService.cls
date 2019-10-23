public class AnswerService extends AbstractDataService {
    private static QuizSessionService sessionService = new QuizSessionService();

    public Quiz_Answer__c create(Id playerId, String answer) {
        // Check game phase and question
        Quiz_Session__c session = sessionService.getQuizSession();
        if (session.Phase__c != QuizSessionService.Phase.Question.name()) {
            throw new InvalidPhaseException();
        }
        Id questionId = session.Current_Question__c;

        // Check for duplicate answer from player
        try {
            getFromPlayer(playerId, questionId);
            throw new DuplicateAnswerException();
        } catch (NoRecordFoundException e) {
        }

        // Save answer
        Quiz_Answer__c answerRecord = new Quiz_Answer__c(
            Player__c = playerId,
            Question__c = questionId,
            Answer__c = answer
        );
        insert answerRecord;
        return answerRecord;
    }

    public Set<Id> getUniquePlayerIds(List<Quiz_Answer__c> answers) {
        Set<Id> playerIds = new Set<Id>();
        for (Quiz_Answer__c answer : answers) {
            if (!playerIds.contains(answer.Player__c)) {
                playerIds.add(answer.Player__c);
            }
        }
        return playerIds;
    }

    public Map<Id, Id> getPlayerQuestionMapping(Set<Id> playerIds) {
        Map<Id, Id> mapPlayerQuestion = new Map<Id, Id>();
        List<Quiz_Answer__c> allAnswers = [
            SELECT Id, Player__c, Question__c
            FROM Quiz_Answer__c
            WHERE Player__c IN :playerIds
            FOR UPDATE
        ];
        for (Quiz_Answer__c answer : allAnswers) {
            mapPlayerQuestion.put(answer.Player__c, answer.Question__c);
        }
        return mapPlayerQuestion;
    }

    public List<Quiz_Answer__c> getAnswersOfPlayerIdsAndQuestionId(
        Set<Id> playerIds,
        Id questionId
    ) {
        // get answers ordered by oldest records first: Id values are created in ascending order
        return [
            SELECT Id, Player__c, Question__c, Answer__c, Timestamp__c, Score__c
            FROM Quiz_Answer__c
            WHERE Player__c IN :playerIds AND Question__c = :questionId
            ORDER BY Id ASC
        ];
    }

    public Quiz_Answer__c getFromPlayer(Id playerId, Id questionId) {
        return (Quiz_Answer__c) getSingleRecord(
            [
                SELECT Id, Player__c, Question__c, Answer__c, Score__c
                FROM Quiz_Answer__c
                WHERE Player__c = :playerId AND Question__c = :questionId
            ]
        );
    }

    public class InvalidPhaseException extends Exception {
    }
    public class DuplicateAnswerException extends Exception {
    }
}