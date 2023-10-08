#pragma once

#include <ostream>

using std::ostream;

typedef struct SchedStrategy_* SchedStrategy;
// typedef struct StrategyWFQ_* StrategyWFQ;

typedef enum {
    UNKNOWNTYPE,
    WFQTYPE
} SchedStrategyType;

struct SchedStrategy_{
    SchedStrategyType type;
    // union {
    //     StrategyWFQ wfq;
    // } u;
};

// struct StrategyWFQ_{
//     int palce_holder;
// };

SchedStrategy SchedStrategyUnknown();
SchedStrategy SchedStrategyWFQ();

void printSchedStrategy(SchedStrategy strategy, ostream& os);