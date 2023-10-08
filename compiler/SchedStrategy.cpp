#include <cassert>
#include "SchedStrategy.h"

SchedStrategy SchedStrategyUnknown(){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = UNKNOWNTYPE;
    return schedStrategy;
}

SchedStrategy SchedStrategyWFQ(){
    SchedStrategy schedStrategy = new SchedStrategy_;
    schedStrategy->type = WFQTYPE;
    return schedStrategy;
}

void printSchedStrategy(SchedStrategy strategy, ostream& os){
    assert(strategy);
    switch(strategy->type){
    case UNKNOWNTYPE:{
        os << "\ttype: unknown\n";
        break;
    }
    case WFQTYPE:{
        os << "\ttype: WFQ\n";
        break;
    }
    }
}